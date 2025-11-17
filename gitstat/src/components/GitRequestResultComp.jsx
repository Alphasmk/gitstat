import { useState, useEffect } from "react";
import { LoadingOutlined } from '@ant-design/icons';
import { Spin, Layout, Flex, Result, Button, Space, Col, Row, Typography } from "antd";
import { useLocation, useNavigate } from 'react-router-dom';
import ReloadButton from "./ReloadButton";
import LinkButton from "./LinkButton";

const { Content } = Layout;

function formatDate(dateString) {
    const date = new Date(dateString);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return `${day}.${month}.${year}`;
}

function GitRequestResultComp() {
    console.log('typeof Result:', typeof Result);
    const [loading, setLoading] = useState(true);
    const [isOk, setIsOk] = useState(true);
    const [errorData, setErrorData] = useState("");
    const [data, setData] = useState(null);
    const [status, setStatus] = useState(200);
    const { search } = useLocation();
    const navigate = useNavigate();

    function getData() {
        setLoading(true);
        setData(null);
        setIsOk(true);

        const params = new URLSearchParams(search);
        const stroke = params.get('stroke');
        fetch(`http://localhost:8000/git_info?stroke=${encodeURIComponent(stroke)}`, {
            method: 'GET',
            credentials: 'include'
        })
            .then(resp => {
                console.log(typeof (resp.ok));
                if (!resp.ok) {
                    return resp.json().then(errorData => {
                        const errorDetail = errorData.detail || errorData.message || 'Неизвестная ошибка';
                        console.error('Error detail:', errorDetail);
                        setStatus(resp.status);
                        setErrorData(errorDetail);
                        setIsOk(false);
                        throw new Error(errorDetail);
                    });
                }
                return resp.json();
            }
            )
            .then(data => {
                if (data.status) {
                    setStatus(data.status);
                    setErrorData("Не найдено");
                    throw new Error("Не найдено");
                }
                setData(data);
                setLoading(false);
            })
            .catch(err => {
                console.error(err);
                setIsOk(false);
                setLoading(false);
            });
    }

    useEffect(() => {
        getData();
    }, []);
    return (
        <Content style={{ padding: '0 0px', flex: 1 }}>
            <div
                className='bg-container'
            >
                {!loading && !isOk ? (
                    <Flex align="center" gap="middle">
                        <Result
                            status="error"
                            title={<span style={{ color: 'white', fontSize: 28 }}>{"Ошибка " + status}</span>}
                            subTitle={<span style={{ color: '#aaa', fontSize: 18 }}>{errorData || "Произошла ошибка при запросе"}</span>}
                            extra={
                                <Button type="primary" className="error-button" onClick={() => navigate("/")}>
                                    На главную
                                </Button>
                            }
                        />
                    </Flex>
                ) : (
                    <Space direction="vertical" style={{ width: '90%', display: loading ? "none" : "block" }}>
                        <Row style={{ backgroundColor: "#12171F", borderRadius: 25 }} align={"middle"} justify={"center"}>
                            <Col flex={1} style={{ backgroundColor: '#1C232F', borderRadius: "25px 0 0 25px", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20 }}>
                                <Space direction="horizontal">
                                    {data?.avatar_url ? (
                                        <img src={data.avatar_url} alt="avatar" style={{ height: 80, borderRadius: '30%', display: "block" }} />
                                    ) : (
                                        <Spin indicator={<LoadingOutlined />} />
                                    )}
                                    {data?.login && data?.created_at && data?.updated_at ? (
                                        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
                                            <div style={{ color: "white", fontSize: 24, fontWeight: 700 }}>
                                                {data.login}
                                            </div>
                                            <div style={{ color: "#8EAEE3", fontSize: 14, fontWeight: 600 }}>
                                                Последнее обновление: {formatDate(data.updated_at)}
                                            </div>
                                            <div style={{ color: "#8EAEE3", fontSize: 14, fontWeight: 600 }}>
                                                Создан: {formatDate(data.created_at)}
                                            </div>
                                        </div>
                                    ) : (
                                        <Spin indicator={<LoadingOutlined />} />
                                    )}
                                </Space>
                            </Col>
                            <Col flex={4}></Col>
                            <Col flex={1} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center" }}>
                                <div style={{ backgroundColor: "#1C232F", display: "flex", width: "fit-content", padding: 15, marginRight: 15, borderRadius: 25 }}>
                                    <LinkButton style={{ height: 60, width: 60, borderRadius: 20, marginRight: 10}} onClick={() => {
                                        window.open(data.html_url, '_blank');
                                    }}></LinkButton>
                                    <ReloadButton style={{ height: 60, width: 60, borderRadius: 20 }} onClick={getData}></ReloadButton>
                                </div>
                            </Col>
                        </Row>
                        <pre style={{ color: "white" }}>{data && JSON.stringify(data, null, 2)}</pre>
                    </Space>
                )}

                {loading ? (
                    <div style={{
                        display: 'flex',
                        justifyContent: 'center',
                        alignItems: 'center',
                        height: '100%',
                        width: '100%',
                    }}>
                        <Spin indicator={<LoadingOutlined style={{ fontSize: 60, color: 'white' }} />} />
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
                        align-items: center;
                    }

                    .error-button {
                        background-color: #883737 !important;
                        padding: 18px;
                        transition: 0.3s;
                        border: 2px solid #C76C6C !important;
                    }

                    .error-button:hover {
                        background-color: #C76C6C !important;
                        border: 2px solid #C76C6C !important;
                    }
                    }
                    `}</style>
        </Content>
    )
}

export default GitRequestResultComp;