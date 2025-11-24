import { useState, useEffect } from "react";
import { LoadingOutlined } from '@ant-design/icons';
import { Spin, Layout, Flex, Result, Button, Space, Col, Row, Typography, Tooltip, Divider } from "antd";
import { useLocation, useNavigate } from 'react-router-dom';
import QueueAnim from 'rc-queue-anim';
import ReloadButton from "./ReloadButton";
import LinkButton from "./LinkButton";
import EmailImage from "../images/email.png"
import LocationImage from "../images/location.png"
import TwitterImage from "../images/twitter.png"
import FollowersImage from "../images/followers.png"
import SubscribesImage from "../images/subscriptions.png"
import BlogImage from "../images/blog.png"

const { Content } = Layout;

function formatDateTime(dateString) {
    const date = new Date(dateString);
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${day}.${month}.${year} ${hours}:${minutes}`;
}

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
    const [pageType, setType] = useState('Profile');
    const [lastUpdate, setLastUpdate] = useState(null);
    const { search } = useLocation();
    const navigate = useNavigate();

    async function getData() {
        setLoading(true);
        setData(null);
        setIsOk(true);

        const params = new URLSearchParams(search);
        const stroke = params.get('stroke');
        const response = await fetch(`http://localhost:8000/new_git_info?stroke=${encodeURIComponent(stroke)}`, {
            method: 'POST',
            credentials: 'include'
        }).then(resp => {
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
            console.log(resp);
            return resp.json();
        }
        )
            .then(data => {
                if (data?.status) {
                    setStatus(data.status);
                    setErrorData("Не найдено");
                    throw new Error("Не найдено");
                }
                setData(data);
                setType(data?.response_type);
                setLastUpdate(data.request_time);
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
        <>
        {loading ? (
                    <div style={{
                        position: 'absolute',
                        top: '50%',
                        left: '50%',
                        transform: 'translate(-50%, -50%)',
                    }}>
                        <Spin indicator={<LoadingOutlined style={{ fontSize: 60, color: 'white' }} />} />
                    </div>
                ) : null}
        { pageType == 'Profile' ? (
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
                ) : pageType == "Profile" ? (
                        <Space direction="vertical" style={{ width: '90%', display: loading ? "none" : "block" }}>
                        <Row style={{ backgroundColor: "#12171F", borderRadius: 25 }} align={"middle"} justify={"center"}>
                            <Col span={8} style={{ backgroundColor: '#1C232F', borderRadius: "25px 0 0 25px", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20 }}>
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
                            <Col span={16} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center" }}>
                                <div style={{ backgroundColor: "#1C232F", display: "flex", width: "fit-content", padding: 15, marginRight: 15, borderRadius: 25 }}>
                                    <LinkButton style={{ height: 60, width: 60, borderRadius: 20, marginRight: 10 }} onClick={() => {
                                        window.open(data?.html_url, '_blank');
                                    }}></LinkButton>
                                    <Tooltip placement="top" title={<span>{"Последний запрос: "}<br />{formatDateTime(lastUpdate)}</span>}>
                                        <span><ReloadButton style={{ height: 60, width: 60, borderRadius: 20 }} onClick={getData}></ReloadButton></span>
                                    </Tooltip>

                                </div>
                            </Col>
                        </Row>
                        <div style={{ marginTop: 20 }}>
                            <Row>
                                <Col span={8} style={{ backgroundColor: '#1C232F', borderRadius: "25px 0 0 0", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20, width: 250 }}>
                                </Col>
                                <Col span={16} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", backgroundColor: '#12171F', borderRadius: "0 25px 0 0" }}>
                                </Col>
                            </Row>
                            <Row style={{minHeight: 400}}>
                                <Col span={8} style={{ backgroundColor: '#1C232F', display: "flex", justifyContent: "flex-start", paddingLeft: 20, alignItems: "center"}}>
                                    <div style={{ display: "flex", width: "100%", flexDirection: "column", alignItems: "stretch" }}>
                                        <div style={{ color: "white", fontWeight: 700, fontSize: 36, textAlign: "left" }}>
                                            {data?.name ? data?.name : data?.login}
                                        </div>
                                        <div>
                                            <div style={{ color: "white", fontSize: 18, textAlign: "left", fontWeight: 600 }}>
                                                ID: {data?.git_id}{<Divider type="vertical" style={{ borderColor: "white" }}></Divider>}{data?.type == "User" ? "Пользователь" : "Организация"}
                                            </div>
                                        </div>
                                        <div style={{ height: "1px", backgroundColor: "#8EAEE3", marginRight: 20, marginTop: 20 }}>

                                        </div>
                                        <Space direction="vertical" size={3} style={{ marginTop: 20 }}>
                                            {data?.email ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                    <Tooltip placement="right" title="Электронная почта">
                                                        <span style={{display: "flex", alignItems: "center"}}><img src={EmailImage} style={{ height: 24, marginRight: 8 }} />{data?.email}</span>
                                                    </Tooltip>
                                                </div>)
                                                : null}
                                            {data?.location ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                    <Tooltip placement="right" title="Местоположение">
                                                         <span style={{display: "flex", alignItems: "center"}}><img src={LocationImage} style={{ height: 24, marginRight: 8 }} /> {data?.location}</span>
                                                    </Tooltip>
                                                </div>)
                                                : null}
                                            {data?.twitter_username ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                    <Tooltip placement="right" title="Twitter">
                                                        <span style={{display: "flex", alignItems: "center"}}><img src={TwitterImage} style={{ height: 24, marginRight: 8 }} /> {data?.twitter_username}</span>
                                                    </Tooltip>
                                                </div>)
                                                : null}
                                            {data?.blog ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                    <Tooltip placement="right" title="Блог">
                                                        <span style={{display: "flex", alignItems: "center"}}>
                                                            <img src={BlogImage} style={{ height: 24, marginRight: 8, fontWeight: 600 }} />
                                                            <a href={data?.blog} style={{ textDecoration: "none", color: "white", fontWeight: 600 }}>
                                                                <span style={{ display: "block" }}>{data?.blog}</span>
                                                            </a>
                                                        </span>
                                                    </Tooltip>
                                                </div>)
                                                : null}
                                        </Space>
                                        {data?.email || data?.location || data?.twitter_username ?
                                            (
                                                <div style={{ height: "1px", backgroundColor: "#8EAEE3", marginRight: 20, marginTop: 20, marginBottom: 20 }}>

                                                </div>
                                            )
                                            : null}
                                        <Space direction="vertical" size={3}>
                                            {data?.followers_count != null ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center"}}>
                                                    <img src={FollowersImage} style={{ height: 24, marginRight: 8 }} /> {data?.followers_count} подписчиков
                                                </div>)
                                                : null}
                                            {data?.following_count != null ? (
                                                <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                    <img src={SubscribesImage} style={{ height: 24, marginRight: 8 }} /> {data?.following_count} подписок
                                                </div>)
                                                : null}
                                        </Space>
                                        {(data?.email || data?.location || data?.twitter_username ) && data?.bio ?
                                            (
                                                <div style={{ height: "1px", backgroundColor: "#8EAEE3", marginRight: 20, marginTop: 20 }}>

                                                </div>
                                            )
                                            : null}
                                        {data?.bio != null ? (
                                            <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center", lineHeight: "25px", marginTop: 20 }}>
                                                {data?.bio}
                                            </div>)
                                            : null}
                                    </div>
                                </Col>
                                <Col span={16} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", backgroundColor: '#12171F' }}>
                                </Col>
                            </Row>
                            <Row>
                                <Col span={8} style={{ backgroundColor: '#1C232F', borderRadius: "0 0 0 25px", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20, width: 250 }}>
                                </Col>
                                <Col span={16} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", backgroundColor: '#12171F', borderRadius: "0 0 25px 0" }}>
                                </Col>
                            </Row>
                        </div>
                        <pre style={{ color: "white" }}>{data && JSON.stringify(data, null, 2)}</pre>
                    </Space>
                    ) : (
                        <div>
                        </div>
                    )}
                )
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
        </Content>) : (<div></div>)}</>
    )
}

export default GitRequestResultComp;