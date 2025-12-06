import { useEffect, useState } from 'react';
import { Table, Select, Switch, Button, Modal, List, message, Spin, ConfigProvider } from 'antd';
import { DeleteOutlined, HistoryOutlined, ExclamationCircleOutlined, LoadingOutlined } from '@ant-design/icons';

function AdminPanelComp() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [currentUserId, setCurrentUserId] = useState(null);
    const [historyModalVisible, setHistoryModalVisible] = useState(false);
    const [selectedUserHistory, setSelectedUserHistory] = useState([]);
    const [historyLoading, setHistoryLoading] = useState(false);
    const [deleteModalVisible, setDeleteModalVisible] = useState(false);
    const [userToDelete, setUserToDelete] = useState(null);

    useEffect(() => {
        fetchUsers();
        fetchCurrentUser();
    }, []);

    const fetchCurrentUser = async () => {
        try {
            const response = await fetch('http://localhost:8000/users/me', {
                credentials: 'include'
            });
            const data = await response.json();
            setCurrentUserId(data.id);
        } catch (error) {
            message.error('Ошибка получения данных пользователя');
        }
    };

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const response = await fetch('http://localhost:8000/users', {
                credentials: 'include'
            });
            const data = await response.json();
            setUsers(data);
        } catch (error) {
            message.error('Ошибка загрузки пользователей');
        } finally {
            setLoading(false);
        }
    };

    const handleRoleChange = async (userId, newRole) => {
        try {
            const response = await fetch(`http://localhost:8000/users/${userId}/role`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify({ role: newRole })
            });

            if (response.ok) {
                message.success('Роль успешно изменена');
                fetchUsers();
            } else {
                message.error('Ошибка изменения роли');
            }
        } catch (error) {
            message.error('Ошибка изменения роли');
        }
    };

    const handleBlockToggle = async (userId, currentBlockState) => {
        try {
            const response = await fetch(`http://localhost:8000/users/${userId}/block`, {
                method: 'PUT',
                credentials: 'include'
            });

            if (response.ok) {
                message.success(currentBlockState === 'Y' ? 'Пользователь разблокирован' : 'Пользователь заблокирован');
                fetchUsers();
            } else {
                message.error('Ошибка изменения статуса блокировки');
            }
        } catch (error) {
            message.error('Ошибка изменения статуса блокировки');
        }
    };

    const handleDelete = (userId, username) => {
        setUserToDelete({ id: userId, username });
        setDeleteModalVisible(true);
    };

    const confirmDelete = async () => {
        try {
            const response = await fetch(`http://localhost:8000/users/${userToDelete.id}`, {
                method: 'DELETE',
                credentials: 'include'
            });

            if (response.ok) {
                message.success('Пользователь удален');
                fetchUsers();
            } else {
                message.error('Ошибка удаления пользователя');
            }
        } catch (error) {
            message.error('Ошибка удаления пользователя');
        } finally {
            setDeleteModalVisible(false);
            setUserToDelete(null);
        }
    };

    const showUserHistory = async (userId, username) => {
        setHistoryModalVisible(true);
        setHistoryLoading(true);
        setSelectedUserHistory([]);

        try {
            const response = await fetch(`http://localhost:8000/history?user_id=${userId}`, {
                credentials: 'include'
            });
            const data = await response.json();
            setSelectedUserHistory(data);
        } catch (error) {
            message.error('Ошибка загрузки истории');
        } finally {
            setHistoryLoading(false);
        }
    };

    function formatDateTime(dateString) {
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${day}.${month}.${year} ${hours}:${minutes}`;
    }

    const columns = [
        {
            title: 'ID',
            dataIndex: 'id',
            key: 'id',
            width: 60,
        },
        {
            title: 'Имя пользователя',
            dataIndex: 'username',
            key: 'username',
        },
        {
            title: 'Почта',
            dataIndex: 'email',
            key: 'email',
        },
        {
            title: 'Роль',
            dataIndex: 'role',
            key: 'role',
            width: 200,
            render: (role, record) => (
                <Select
                    value={role}
                    style={{ width: '100%' }}
                    onChange={(value) => handleRoleChange(record.id, value)}
                    disabled={record.id === currentUserId}
                >
                    <Select.Option value="user">Пользователь</Select.Option>
                    <Select.Option value="moderator">Модератор</Select.Option>
                    <Select.Option value="admin">Администратор</Select.Option>
                </Select>
            ),
        },
        {
            title: 'Блокировка',
            dataIndex: 'is_blocked',
            key: 'is_blocked',
            width: 120,
            align: 'center',
            render: (isBlocked, record) => (
                <Switch
                    checked={isBlocked === 'Y'}
                    onChange={() => handleBlockToggle(record.id, isBlocked)}
                    disabled={record.role === 'admin' || record.role === 'moderator'}
                    checkedChildren="Да"
                    unCheckedChildren="Нет"
                />
            ),
        },
        {
            title: 'Дата регистрации',
            dataIndex: 'created_at',
            key: 'created_at',
            width: 180,
            render: (date) => formatDateTime(date),
        },
        {
            title: 'Действия',
            key: 'actions',
            width: 150,
            align: 'center',
            render: (_, record) => (
                <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
                    <Button
                        type="primary"
                        icon={<HistoryOutlined />}
                        onClick={() => showUserHistory(record.id, record.username)}
                        disabled={record.id === currentUserId}
                        style={{
                            backgroundColor: record.id === currentUserId ? '#0D1117' : '#1F6FEB',
                            border: record.id === currentUserId ? '1px solid #6B7280' : 'none',
                            color: record.id === currentUserId ? '#6B7280' : '#ffffff'
                        }}
                    >
                        История
                    </Button>
                    <Button
                        danger
                        icon={<DeleteOutlined />}
                        onClick={() => handleDelete(record.id, record.username)}
                        disabled={record.role === 'admin' || record.role === 'moderator' || record.id === currentUserId}
                        style={{
                            backgroundColor: (record.role === 'admin' || record.role === 'moderator' || record.id === currentUserId) ? '#0D1117' : '#883737',
                            border: (record.role === 'admin' || record.role === 'moderator' || record.id === currentUserId) ? '1px solid #6B7280' : '1px solid #C76C6C',
                            color: (record.role === 'admin' || record.role === 'moderator' || record.id === currentUserId) ? '#6B7280' : '#ffffff'
                        }}
                    >
                        Удалить
                    </Button>
                </div>
            ),
        },
    ];

    return (
        <>
            <div className='bg-container'>
                <div style={{ width: "80%" }}>
                    <div style={{ color: "white", fontSize: 28, fontWeight: 700, marginBottom: 20 }}>
                        Панель администратора
                    </div>
                    <Table
                        columns={columns}
                        dataSource={users}
                        rowKey="id"
                        loading={loading}
                        pagination={{
                            pageSize: 10,
                            showSizeChanger: false,
                            align: 'center',
                        }}
                        style={{
                            backgroundColor: '#1C232F',
                            borderRadius: 15,
                        }}
                    />
                </div>
            </div>

            <Modal
                title={<span style={{ color: 'white' }}>История запросов пользователя</span>}
                open={historyModalVisible}
                onCancel={() => setHistoryModalVisible(false)}
                footer={null}
                width={700}
                styles={{
                    content: { backgroundColor: '#262E3B' },
                    header: { backgroundColor: '#262E3B' }
                }}
            >
                {historyLoading ? (
                    <div style={{ textAlign: 'center', padding: 40 }}>
                        <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: '#8EAEE3' }} />} />
                    </div>
                ) : selectedUserHistory.length > 0 ? (
                    <List
                        dataSource={selectedUserHistory}
                        renderItem={(item) => (
                            <List.Item style={{ borderBottom: '1px solid #262E3B', backgroundColor: 'transparent' }}>
                                <div style={{ width: '100%' }}>
                                    <div style={{ fontWeight: 600, fontSize: 16, color: 'white' }}>
                                        {item.obj_name}
                                    </div>
                                    <div style={{ color: '#8EAEE3', fontSize: 14 }}>
                                        {item.request_type === 'REPOSITORY' ? 'Репозиторий' : 'Профиль'} • ID: {item.obj_id}
                                    </div>
                                    <div style={{ color: '#6B7280', fontSize: 12, marginTop: 4 }}>
                                        {formatDateTime(item.request_time)}
                                    </div>
                                </div>
                            </List.Item>
                        )}
                    />
                ) : (
                    <div style={{ textAlign: 'center', padding: 40, color: '#8EAEE3' }}>
                        История запросов пуста
                    </div>
                )}
            </Modal>

            <Modal
                title={<span style={{ color: 'white' }}>Удаление пользователя</span>}
                open={deleteModalVisible}
                onOk={confirmDelete}
                onCancel={() => {
                    setDeleteModalVisible(false);
                    setUserToDelete(null);
                }}
                okText="Удалить"
                okButtonProps={{
                    danger: true,
                    style: { backgroundColor: '#883737', border: '1px solid #C76C6C' }
                }}
                cancelText="Отмена"
                cancelButtonProps={{
                    style: { backgroundColor: '#262E3B', border: '1px solid #8EAEE3', color: '#8EAEE3' }
                }}
                styles={{
                    content: { backgroundColor: '#1C232F' },
                    header: { backgroundColor: '#1C232F' }
                }}
            >
                <p style={{ display: 'flex', alignItems: 'center', gap: 8, color: 'white' }}>
                    <ExclamationCircleOutlined style={{ color: '#ff4d4f', fontSize: 22 }} />
                    Вы уверены, что хотите удалить пользователя<strong>{userToDelete?.username}</strong>?
                </p>
            </Modal>

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

                .ant-table {
                    background-color: #1C232F !important;
                }

                .ant-table-thead > tr > th {
                    background-color: #262E3B !important;
                    color: #FFFFFF !important;
                    font-weight: 600 !important;
                    border-bottom: 2px solid #0D1117 !important;
                }

                .ant-table-tbody > tr > td {
                    background-color: #1C232F !important;
                    color: white !important;
                    border-bottom: 1px solid #262E3B !important;
                }

                .ant-table-tbody > tr:hover > td {
                    background-color: #262E3B !important;
                }

                .ant-pagination-item {
                    background-color: transparent !important;
                    color: #8EAEE3 !important;
                    border: 1px solid #8EAEE3 !important;
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
                    background-color: transparent !important;
                    border: 1px solid #8EAEE3 !important;
                }

                .ant-select-dropdown {
                    background-color: #262E3B !important;
                }

                .ant-select-item {
                    color: white !important;
                    background-color: #262E3B !important;
                }

                .ant-select-item-option-selected {
                    background-color: #1F6FEB !important;
                    color: white !important;
                }

                .ant-select-item-option-active {
                    background-color: #1C232F !important;
                }

                .ant-select-selector {
                    background-color: #1C232F !important;
                    border-color: #8EAEE3 !important;
                    color: white !important;
                }

                .ant-select-arrow {
                    color: #8EAEE3 !important;
                }

                .ant-select-disabled .ant-select-selector {
                    background-color: #0D1117 !important;
                    border-color: #6B7280 !important;
                    color: #6B7280 !important;
                    cursor: not-allowed !important;
                }

                .ant-select-disabled .ant-select-arrow {
                    color: #6B7280 !important;
                }

                .ant-btn-primary:not(:disabled):hover {
                    background-color: #4A8FFF !important;
                    border-color: #4A8FFF !important;
                }

                .ant-btn-dangerous:not(:disabled):hover {
                    background-color: #A54545 !important;
                    border-color: #D88888 !important;
                    color: #FFFFFF !important;
                }

                .ant-btn:disabled:hover {
                    background-color: #0D1117 !important;
                    border-color: #6B7280 !important;
                    color: #6B7280 !important;
                    cursor: not-allowed !important;
                }

                .ant-btn-default:hover {
                    background-color: #354150 !important;
                    border-color: #9CB3CE !important;
                    color: #9CB3CE !important;
                }
            `}</style>
        </>
    );
}

export default AdminPanelComp;
