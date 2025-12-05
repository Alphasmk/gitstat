from pwdlib import PasswordHash
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import hashlib
import os
from typing import Optional
import base64


class EncryptHelper:
    password_hash = PasswordHash.recommended()
    
    ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY")
    _key_bytes = None

    @staticmethod
    def verify_password(plain_password, hashed_password):
        return EncryptHelper.password_hash.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password):
        return EncryptHelper.password_hash.hash(password)
    
    @staticmethod
    def _get_key_bytes():
        if EncryptHelper._key_bytes is None:
            if not EncryptHelper.ENCRYPTION_KEY:
                raise ValueError("ENCRYPTION_KEY не установлен")
            key = EncryptHelper.ENCRYPTION_KEY
            if isinstance(key, str):
                key = key.encode()
            EncryptHelper._key_bytes = hashlib.sha256(key).digest()
        return EncryptHelper._key_bytes
    
    @staticmethod
    def encrypt_data(data: str) -> str:
        key = EncryptHelper._get_key_bytes()
        iv = hashlib.md5(data.encode()).digest()
        
        padded_data = data.encode()
        padding_length = 16 - (len(padded_data) % 16)
        padded_data += bytes([padding_length] * padding_length)
        
        cipher = Cipher(
            algorithms.AES(key),
            modes.CBC(iv),
            backend=default_backend()
        )
        encryptor = cipher.encryptor()
        encrypted = encryptor.update(padded_data) + encryptor.finalize()
        
        result = iv + encrypted
        return base64.b64encode(result).decode()
    
    @staticmethod
    def decrypt_data(encrypted_data: str) -> str:
        key = EncryptHelper._get_key_bytes()
        
        try:
            full_data = base64.b64decode(encrypted_data.encode())
            iv = full_data[:16]
            encrypted_bytes = full_data[16:]
            
            cipher = Cipher(
                algorithms.AES(key),
                modes.CBC(iv),
                backend=default_backend()
            )
            decryptor = cipher.decryptor()
            decrypted_with_padding = decryptor.update(encrypted_bytes) + decryptor.finalize()
            
            padding_length = decrypted_with_padding[-1]
            if 1 <= padding_length <= 16:
                decrypted = decrypted_with_padding[:-padding_length]
                return decrypted.decode()
            
            raise ValueError("Неверный padding")
        except Exception as e:
            raise ValueError(f"Ошибка при расшифровке: {str(e)}")
    
    @staticmethod
    def generate_encryption_key() -> str:
        from cryptography.fernet import Fernet
        return Fernet.generate_key().decode()
