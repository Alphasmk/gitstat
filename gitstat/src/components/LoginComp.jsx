import React, { useState } from 'react';
import { Button, Form, Input, Space, Typography, notification } from 'antd';
import '../styles/LoginComp.css';
import logo from '../images/github_logo.png';
import axios from 'axios';
import { useTransition, animated } from 'react-spring';

const { Text, Link } = Typography;

const onFinishFailed = (errorInfo) => {
  console.log('Failed:', errorInfo);
};

function LoginComp() {
  const [isLogin, setIsLogin] = useState(true);
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
    console.log('Form values:', values);
    const formData = new URLSearchParams();
    formData.append('username', values.username);
    formData.append('password', values.password);
    try {
      const response = await axios.post('http://127.0.0.1:8000/token', formData, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      });
      console.log('Server response:', response.data);
      openNotification('Успешный вход', `Вы вошли как ${values.username}`);
    } catch (error) {
      console.error('Error logging in:', error);
      openNotification('Ошибка', `Неверный логин или пароль`);
    }
  };

  const onFinishRegister = async (values) => {
    console.log('Form values:', values);
    const formData = {
      'username': values.username,
      'email': values.email,
      'password': values.password
    }
    try {
      const response = await axios.post('http://127.0.0.1:8000/register', formData, {
        headers: { 'Content-Type': 'application/json' },
      });
      console.log('Server response:', response.data);
      openNotification('Успешная регистрация', `Вы зарегистрировались как ${values.username}`);
    } catch (error) {
      console.error('Ошибка регистрации:', error);
      openNotification('Ошибка', `Неверный логин или пароль`);
    }
  }

  const transitions = useTransition(isLogin, {
    from: { opacity: 0, transform: 'translate3d(100%,0,0)' },
    enter: { opacity: 1, transform: 'translate3d(0%,0,0)' },
    leave: { opacity: 0, transform: 'translate3d(-50%,0,0)' },
    config: { duration: 200 },
  });

  return (
    <div
      style={{
        position: 'relative',
        width: 320,
        height: 550,
        overflow: 'hidden',
        borderRadius: 16,
      }}
    >
      {contextHolder}
      {transitions((style, item) =>
        item ? (
          <animated.div style={{ ...style, position: 'absolute', width: '100%' }}>
            <Form
              name="login"
              layout="vertical"
              style={{ color: 'white', textAlign: 'center' }}
              onFinish={onFinishLogin}
              onFinishFailed={onFinishFailed}
              autoComplete="off"
            >
              <img src={logo} alt="Logo" style={{ width: 60, marginBottom: 0 }} />
              <h2 style={{ color: 'white', marginBottom: 20 }}>Войти в GitStat</h2>

              <Form.Item
                label="Имя пользователя или email"
                name="username"
              >
                <Input />
              </Form.Item>

              <Form.Item
                label="Пароль"
                name="password"
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
          <animated.div style={{ ...style, position: 'absolute', width: '100%' }}>
            <Form
              name="register"
              layout="vertical"
              style={{ color: 'white', textAlign: 'center' }}
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
                <Button type="primary" htmlType="submit" style={{ width: '100%', marginBottom: 0 }}>
                  Зарегистрироваться
                </Button>
              </Form.Item>

              <Space direction="vertical" size={2} style={{ marginBottom: 0 }} >
                <Text style={{ color: 'white' }}>Уже есть аккаунт?</Text>
                <Link onClick={() => setIsLogin(true)}>Войти</Link>
              </Space>
            </Form>
          </animated.div>
        )
      )}
    </div>
  );
}

export default LoginComp;
