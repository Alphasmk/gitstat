import { Layout, Menu, Col, Row, Space, Typography, Button } from 'antd';
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import logoutImage from '../images/logout.png'
const { Header } = Layout;

// const items = [
//         { key: '/', label: 'Главная' },
//         { key: '/history', label: 'История' },
//     ];

function HeaderComp() {
    const [username, setUsername] = useState('');
    const [items, setItems] = useState([
        { key: '/', label: 'Главная' },
        { key: '/history', label: 'История' },
    ])
    const navigate = useNavigate();
    const handleMenuClick = (e) => {
        navigate(e.key);
    };
    function logout() {
        fetch('http://localhost:8000/logout', {
            method: 'POST',
            credentials: 'include'
        }).then(() => {
            navigate('/login');
        })
    }
        useEffect(() => {
        fetch('http://localhost:8000/users/me', {
            method: 'GET',
            credentials: 'include'
        }).then(resp => resp.json()).then(
            data => {
                setUsername(data.username);

                let items_key = "";
                let items_label = "";

                if(data.role === "admin") {
                    items_key = '/admin';
                    items_label = 'Панель администратора';
                }
                else if(data.role === "moderator") {
                    items_key = '/moderator';
                    items_label = 'Панель модератора';
                }

                if(data.role !== "user") {
                    setItems([
                        { key: '/', label: 'Главная' },
                        { key: '/history', label: 'История' },
                        { key: items_key, label: items_label}
                    ]);
                }
            }
        )
    }, []);
    return (
        <Header style={{ backgroundColor: '#12171F', padding: '0 40px' }}>
            <Row align="middle" justify="space-between">
                <Col flex="80px"></Col>
                <Col flex="120px">
                    <div style={{
                        display: 'flex',
                        justifyContent: 'left',
                        alignItems: 'center'
                    }}>
                        <img src='../../github_logo.png' style={{ height: 45 }} />
                    </div>
                </Col>

                <Col flex="auto">
                    <div
                        style={{
                            display: 'flex',
                            justifyContent: 'center',
                        }}
                    >
                        <Menu
                            theme="dark"
                            className="main-menu"
                            mode="horizontal"
                            defaultSelectedKeys={['1']}
                            selectedKeys={[location.pathname]}
                            items={items}
                            overflowedIndicator={null}
                            onClick={handleMenuClick}
                            style={{
                                backgroundColor: '#12171F',
                                borderBottom: 'none',
                                display: 'flex',
                                justifyContent: 'center',
                                flex: 1,
                            }}
                        />
                    </div>
                </Col>

                <Col style={{ textAlign: 'right', color: 'white' }}>
                    <Space direction='horizontal'>
                        <Typography.Text style={{ fontWeight: 600, fontSize: 16 }}>
                            {username}
                        </Typography.Text>
                        <Button className='logout-button' style={{ width: 14, height: 14 }} onClick={logout}>
                            <img src={logoutImage} style={{ height: 16 }} />
                        </Button>
                    </Space>
                </Col>
                <Col flex="80px"></Col>
            </Row>
            <style jsx>
                {`
                            .logout-button {
                                background-color: #883737 !important;
                                padding: 18px;
                                display: flex;
                                justify-content: center;
                                align-items: center;
                                transition: 0.3s;
                                border: 2px solid #C76C6C !important;
                            }

                            .logout-button:hover {
                                background-color: #C76C6C !important;
                                border: 2px solid #C76C6C !important;
                            }
                        `}
            </style>
        </Header>
    );
}

export default HeaderComp;
