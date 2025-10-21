from pwdlib import PasswordHash

class Hasher:
    password_hash = PasswordHash.recommended()

    @staticmethod
    def verify_password(plain_password, hashed_password):
        return Hasher.password_hash.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password):
        return Hasher.password_hash.hash(password)
