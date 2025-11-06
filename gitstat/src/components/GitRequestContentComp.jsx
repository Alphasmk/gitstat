import { Layout, Input, Form, Space, Typography, Button, notification } from 'antd';
import { useState } from 'react';
import githubLogo from '../images/github_logo.png';
import sendImages from '../images/send.png'
import { useNavigate } from 'react-router-dom';

const { Content } = Layout;

function GitRequestContentComp() {
    const [isInputFocused, setInputFocus] = useState(false);
    const [api, contextHolder] = notification.useNotification();
    const navigate = useNavigate();

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

    const onRequestFinish = async (values) => {
        if (values.input.trim() != "") {
            navigate(`/git_result?stroke=${values.input}`)
            // await fetch(`http://localhost:8000/git_info?stroke=${encodeURIComponent(values.input)}`, {
            //     method: 'GET',
            //     credentials: 'include'
            // })
            //     .then(resp => resp.json())
            //     .then(data => openNotification('Успех!', JSON.stringify(data, null, 2)))
            //     .catch(e => openNotification('Ошибка!', String(e)))
        }
    }


    return (
        <Content style={{ padding: '0 0px', flex: 1 }}>
            {contextHolder}
            <div
                className='bg-container'
            >
                <Form
                    name='GitRequest'
                    layout='vertical'
                    onFinish={onRequestFinish}
                >
                    <Space direction='vertical' size={20}>
                        <Typography.Title style={{
                            margin: 0,
                            color: '#fff',
                            transform: isInputFocused ? 'scale(1)' : 'scale(0.9)',
                            transition: 'transform 0.3s ease'
                        }} level={3}>
                            Получите статистику по любому<br />
                            GitHub репозиторию или профилю
                        </Typography.Title>

                        <Space direction='horizontal' size={5}>
                            <Form.Item
                                name="input"
                            >
                                <Input className='query-input'
                                    placeholder="Введите ссылку на репозиторий, профиль или имя пользователя"
                                    onFocus={() => setInputFocus(true)}
                                    onBlur={() => setInputFocus(false)} />
                            </Form.Item>
                            <Form.Item>
                                <Button className='send-button' type="primary" htmlType="submit" style={{ width: 40 }}>
                                    <img src={sendImages} style={{ height: 20 }} />
                                </Button>
                            </Form.Item>
                        </Space>
                    </Space>
                </Form>

            </div>
            <style jsx>{`
                .bg-container {
                    background-image: linear-gradient(rgba(13, 17, 23, 0.9), rgba(13, 17, 23, 0.9)), url(${githubLogo});
                    background-size: auto, ${isInputFocused ? '70%' : '80%'};
                    background-position: center;
                    background-repeat: no-repeat;
                    background-color: #0D1117;
                    height: 100%;
                    min-height: calc(100vh - 134px);
                    padding: 24px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    transition: background-size 0.3s ease;
                }

                .send-button {
                    background-color: #408837 !important;
                    transition: 0.3s;
                    border: 2px solid #76C76C !important;
                }

                .send-button:hover {
                    background-color: #76C76C !important;
                    border: 2px solid #76C76C !important;
                }

                .query-input{
                    width: ${isInputFocused ? '35vw' : '30vw'};
                    font-weight: 600;
                }

                .query-input::placeholder {
                    color: #313B4B;
                    font-weight: 600;
                }
            `}</style>
        </Content>
    )
}

export default GitRequestContentComp;