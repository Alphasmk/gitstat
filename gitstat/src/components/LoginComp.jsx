import React, { useState, useRef, useEffect } from 'react';
import { Button, Form, Input, Space, Typography, notification } from 'antd';
import '../styles/LoginComp.css';
import logo from '../images/github_logo.png';
import axios from 'axios';
import { useSpring, animated, useTransition } from 'react-spring';

const { Text, Link } = Typography;

const onFinishFailed = (errorInfo) => {
  console.log('Failed:', errorInfo);
};

function LoginComp() {
  const [isLogin, setIsLogin] = useState(true);
  const loginRef = useRef(null);
  const registerRef = useRef(null);
  const [height, setHeight] = useState(0);
  const [api, contextHolder] = notification.useNotification();

  const openNotification = (msg, descr) => {
    api.info({
      message: msg,
      description: descr,
      placement: 'top',
      style: {
        backgroundColor: '#2F3743',
        color: 'white',
        borderRadius: '10px',
        overflow: 'hidden',
      },
    });
  };

  const onFinishLogin = async (values) => {
    const formData = new URLSearchParams();
    formData.append('username', values.username);
    formData.append('password', values.password);
    try {
      const response = await axios.post('http://127.0.0.1:8000/token', formData, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      });
      openNotification('Успешный вход', `Вы вошли как ${values.username}`);
    } catch {
      openNotification('Ошибка', `Неверный логин или пароль`);
    }
  };

  const onFinishRegister = async (values) => {
    const formData = {
      username: values.username,
      email: values.email,
      password: values.password,
    };
    try {
      const response = await axios.post('http://127.0.0.1:8000/register', formData, {
        headers: { 'Content-Type': 'application/json' },
      });
      openNotification('Успешная регистрация', `Вы зарегистрировались как ${values.username}`);
    } catch {
      openNotification('Ошибка', `Неверный логин или пароль`);
    }
  };

  // 🔧 Меняем переход — без translate, только прозрачность
  const transitions = useTransition(isLogin, {
    from: { opacity: 0, position: 'absolute', width: '100%' },
    enter: { opacity: 1 },
    leave: { opacity: 0 },
    config: { duration: 250 },
  });

  // корректное измерение высоты формы
  useEffect(() => {
    const activeRef = isLogin ? loginRef : registerRef;
    const timeout = setTimeout(() => {
      if (activeRef.current) setHeight(activeRef.current.offsetHeight);
    }, 0);
    return () => clearTimeout(timeout);
  }, [isLogin]);

  const parentSpring = useSpring({
    height,
    config: { tension: 250, friction: 26 },
  });

  return (
    <animated.div
      style={{
        ...parentSpring,
        position: 'relative',
        width: 350,
        borderRadius: 16,
        backgroundColor: '#12171F',
        overflow: 'hidden',
        padding: 0,
      }}
    >
      {contextHolder}

      {transitions((style, item) =>
        item ? (
          // === Форма входа ===
          <animated.div ref={loginRef} style={{ ...style }}>
            <Form
              name="login"
              layout="vertical"
              style={{ color: 'white', textAlign: 'center', margin: 20 }}
              onFinish={onFinishLogin}
              onFinishFailed={onFinishFailed}
              autoComplete="off"
            >
              <img src={logo} alt="Logo" style={{ width: 60, marginBottom: 0 }} />
              <h2 style={{ color: 'white', marginBottom: 20 }}>Войти в GitStat</h2>

              <Form.Item
                label="Имя пользователя или email"
                name="username"
                rules={[{ required: true, message: 'Введите имя пользователя или email!' }]}
              >
                <Input />
              </Form.Item>

              <Form.Item
                label="Пароль"
                name="password"
                rules={[{ required: true, message: 'Введите пароль!' }]}
              >
                <Input.Password />
              </Form.Item>

              <Form.Item>
                <Button type="primary" htmlType="submit" style={{ width: '100%' }}>
                  Войти
                </Button>
              </Form.Item>

              <Space direction="vertical" size={2}>
                <Text style={{ color: 'white' }}>Ещё нет аккаунта?</Text>
                <Link onClick={() => setIsLogin(false)}>Создать аккаунт</Link>
              </Space>
            </Form>
          </animated.div>
        ) : (
          // === Форма регистрации ===
          <animated.div ref={registerRef} style={{ ...style }}>
            <Form
              name="register"
              layout="vertical"
              style={{ color: 'white', textAlign: 'center', margin: 20 }}
              onFinish={onFinishRegister}
              autoComplete="off"
            >
              <img src={logo} alt="Logo" style={{ width: 60, marginBottom: 0 }} />
              <h2 style={{ color: 'white', marginBottom: 20 }}>Создать аккаунт</h2>

              <Form.Item
                label="Имя пользователя"
                name="username"
                rules={[{ required: true, message: 'Введите имя пользователя!' }]}
              >
                <Input />
              </Form.Item>

              <Form.Item
                label="Email"
                name="email"
                rules={[{ required: true, message: 'Введите email!' }]}
              >
                <Input type="email" />
              </Form.Item>

              <Form.Item
                label="Пароль"
                name="password"
                rules={[{ required: true, message: 'Введите пароль!' }]}
              >
                <Input.Password />
              </Form.Item>

              <Form.Item>
                <Button type="primary" htmlType="submit" style={{ width: '100%' }}>
                  Зарегистрироваться
                </Button>
              </Form.Item>

              <Space direction="vertical" size={2}>
                <Text style={{ color: 'white' }}>Уже есть аккаунт?</Text>
                <Link onClick={() => setIsLogin(true)}>Войти</Link>
              </Space>
            </Form>
          </animated.div>
        )
      )}
    </animated.div>
  );
}

export default LoginComp;
