import { useEffect, useState } from 'react';
import { List, Spin, message } from 'antd';
import { useNavigate } from 'react-router-dom';
import { LoadingOutlined } from '@ant-design/icons';
import { GithubOutlined, UserOutlined } from '@ant-design/icons';

function HistoryComp() {
    const [loading, setLoading] = useState(true);
    const [historyData, setHistoryData] = useState([]);
    const [showSlowLoadingMessage, setShowSlowLoadingMessage] = useState(false);
    const navigate = useNavigate();

    function formatDateTime(dateString) {
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${day}.${month}.${year} ${hours}:${minutes}`;
    }

    useEffect(() => {
        const fetchHistory = async () => {
            setLoading(true);
            setShowSlowLoadingMessage(false);

            const slowLoadingTimer = setTimeout(() => {
                setShowSlowLoadingMessage(true);
            }, 3000);

            try {
                const userResponse = await fetch('http://localhost:8000/users/me', {
                    credentials: 'include'
                });
                
                if (!userResponse.ok) {
                    throw new Error('Ошибка получения данных пользователя');
                }
                
                const userData = await userResponse.json();
                
                const historyResponse = await fetch(
                    `http://localhost:8000/history?user_id=${userData.id}`,
                    {
                        credentials: 'include'
                    }
                );
                
                if (!historyResponse.ok) {
                    throw new Error('Ошибка получения истории');
                }
                
                const history = await historyResponse.json();
                setHistoryData(history);
            } catch (error) {
                message.error(error.message);
                console.error('Ошибка:', error);
            } finally {
                clearTimeout(slowLoadingTimer);
                setLoading(false);
            }
        };

        fetchHistory();
    }, []);

    return (
        <>
            {loading ? (
                <div style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                }}>
                    <div style={{
                        color: '#8EAEE3',
                        fontSize: 16,
                        maxWidth: 600,
                        textAlign: 'center',
                        opacity: showSlowLoadingMessage ? 1 : 0,
                        transition: 'opacity 0.5s ease-in-out',
                        pointerEvents: showSlowLoadingMessage ? 'auto' : 'none',
                        marginBottom: 15,
                        fontWeight: 600
                    }}>
                        Загружаем вашу историю просмотров...
                    </div>
                    <Spin indicator={<LoadingOutlined style={{ fontSize: 60, marginBottom: 15, color: 'white' }} />} />
                </div>
            ) : null}
            
            <div className='bg-container'>
                {!loading && historyData && historyData.length > 0 ? (
                    <div style={{ width: "70%" }}>
                        <div style={{ color: "white", fontSize: 28, fontWeight: 700, marginBottom: 20 }}>
                            История запросов ({historyData.length})
                        </div>
                        <List
                            dataSource={historyData}
                            pagination={{
                                pageSize: 6,
                                showSizeChanger: false,
                                align: 'center',
                                position: 'bottom',
                                showLessItems: false
                            }}
                            renderItem={(item) => (
                                <List.Item
                                    style={{
                                        backgroundColor: "#1C232F",
                                        borderRadius: 15,
                                        marginBottom: 15,
                                        padding: 16,
                                        border: "none",
                                        transition: "0.3s"
                                    }}
                                    onMouseEnter={(e) => {
                                        e.currentTarget.style.backgroundColor = "#262E3B";
                                    }}
                                    onMouseLeave={(e) => {
                                        e.currentTarget.style.backgroundColor = "#1C232F";
                                    }}
                                >
                                    <div style={{ width: "100%", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                                        <div style={{ display: "flex", alignItems: "center", gap: 15, flex: 1 }}>
                                            <div style={{
                                                backgroundColor: item.request_type === 'REPOSITORY' ? '#238636' : '#1F6FEB',
                                                borderRadius: 10,
                                                padding: 12,
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                minWidth: 48,
                                                height: 48
                                            }}>
                                                {item.request_type === 'REPOSITORY' ? (
                                                    <GithubOutlined style={{ fontSize: 24, color: 'white' }} />
                                                ) : (
                                                    <UserOutlined style={{ fontSize: 24, color: 'white' }} />
                                                )}
                                            </div>
                                            
                                            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
                                                <div style={{ color: "white", fontSize: 22, fontWeight: 600 }}>
                                                    {item.obj_name}
                                                </div>
                                                <div style={{ color: "#8EAEE3", fontSize: 14, marginTop: 4 }}>
                                                    {item.request_type === 'REPOSITORY' ? 'Репозиторий' : 'Профиль'} • ID: {item.obj_id}
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <div style={{ color: "#8EAEE3", fontSize: 14, textAlign: "right", whiteSpace: "nowrap" }}>
                                            {formatDateTime(item.request_time)}
                                        </div>
                                    </div>
                                </List.Item>
                            )}
                        />
                    </div>
                ) : !loading ? (
                    <div style={{ color: "#8EAEE3", fontSize: 18, textAlign: "center" }}>
                        История просмотров пуста
                    </div>
                ) : null}
            </div>
            <style jsx>{`
                .bg-container {
                    background-color: #0D1117;
                    height: 100%;
                    min-height: calc(100vh - 134px);
                    padding: 24px;
                    display: flex;
                    justify-content: center;
                    align-items: flex-start;
                }

                .ant-pagination-item {
                    background-color: transparent !important;
                    color: #8EAEE3 !important;
                    border: 1px solid #8EAEE3 !important;
                    transition: 0.3s;
                }
                
                .ant-pagination-item:hover {
                    background-color: #8EAEE3 !important;
                }
                
                .ant-pagination-item:hover a {
                    color: black !important;
                }

                .ant-pagination-item a {
                    color: #8EAEE3 !important;
                }

                .ant-pagination-item-link {
                    color: #8EAEE3 !important;
                }

                .ant-pagination-item-link,
                .ant-pagination-item-link-icon,
                .ant-pagination-item-ellipsis {
                    color: #8EAEE3 !important;
                }
            `}</style>
        </>
    );
}

export default HistoryComp;
