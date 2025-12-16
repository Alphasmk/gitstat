import { useState, useEffect } from "react";
import { LoadingOutlined } from '@ant-design/icons';
import { Spin, Layout, Flex, Result, Button, Space, Col, Row, Typography, Tooltip, Divider, List, Radio } from "antd";
import { useLocation, useNavigate } from 'react-router-dom';
import LanguagesDiagram from "./LanguagesDiagram.jsx";
import ReloadButton from "./ReloadButton";
import LinkButton from "./LinkButton";
import EmailImage from "../images/email.png"
import LocationImage from "../images/location.png"
import TwitterImage from "../images/twitter.png"
import SubscribesImage from "../images/subscriptions.png"
import BlogImage from "../images/blog.png"
import IdImage from "../images/id.png"
import BranchImage from "../images/branch.png"
import StarsImage from "../images/star.png"
import ForksImage from "../images/forks.png"
import CodeImage from "../images/code.png"
import IssuesImage from "../images/issues.png"
import FollowersImage from "../images/followers.png"
import LicenseImage from "../images/license.png"
import { languageIcons } from "./languageIcons.jsx";

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
    const [showSlowLoadingMessage, setShowSlowLoadingMessage] = useState(false);
    const [isOk, setIsOk] = useState(true);
    const [errorData, setErrorData] = useState("");
    const [data, setData] = useState(null);
    const [status, setStatus] = useState(200);
    const [pageType, setType] = useState('Profile');
    const [lastUpdate, setLastUpdate] = useState(null);
    const { search } = useLocation();
    const navigate = useNavigate();

    async function getData(isRenew) {
        setLoading(true);
        setData(null);
        setIsOk(true);
        setShowSlowLoadingMessage(false);

        const slowLoadingTimer = setTimeout(() => {
            setShowSlowLoadingMessage(true);
        }, 3000);

        const endpoint = isRenew ? 'new_git_info' : 'check_git_info';
        const params = new URLSearchParams(search);
        const stroke = params.get('stroke');
        const response = await fetch(`http://localhost:8000/${endpoint}?stroke=${encodeURIComponent(stroke)}`, {
            method: isRenew ? 'GET' : 'POST',
            credentials: 'include'
        }).then(resp => {
            clearTimeout(slowLoadingTimer);
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
                clearTimeout(slowLoadingTimer);
                console.error(err);
                setIsOk(false);
                setLoading(false);
            });
    }

    useEffect(() => {
        getData();
    }, [search]);
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
                        Загрузка может идти дольше, если запрос по GitHub еще не проводился, или если вы обновляете данные
                    </div>
                    <Spin indicator={<LoadingOutlined style={{ fontSize: 60, marginBottom: 15, color: 'white' }} />} />
                </div>
            ) : null}
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
                                        <Tooltip placement="top" title={<span>{"Последний запрос: "}<br />{lastUpdate ? formatDateTime(lastUpdate) : "Только что"}</span>}>
                                            <span><ReloadButton style={{ height: 60, width: 60, borderRadius: 20 }} onClick={() => getData(true)}></ReloadButton></span>
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
                                <Row style={{ minHeight: 400 }}>
                                    <Col span={8} style={{ backgroundColor: '#1C232F', display: "flex", justifyContent: "flex-start", paddingLeft: 20, alignItems: "center" }}>
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
                                                            <span style={{ display: "flex", alignItems: "center" }}><img src={EmailImage} style={{ height: 24, marginRight: 8 }} />{data?.email}</span>
                                                        </Tooltip>
                                                    </div>)
                                                    : null}
                                                {data?.location ? (
                                                    <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                        <Tooltip placement="right" title="Местоположение">
                                                            <span style={{ display: "flex", alignItems: "center" }}><img src={LocationImage} style={{ height: 24, marginRight: 8 }} /> {data?.location}</span>
                                                        </Tooltip>
                                                    </div>)
                                                    : null}
                                                {data?.twitter_username ? (
                                                    <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                        <Tooltip placement="right" title="Twitter">
                                                            <span style={{ display: "flex", alignItems: "center" }}><img src={TwitterImage} style={{ height: 24, marginRight: 8 }} /> {data?.twitter_username}</span>
                                                        </Tooltip>
                                                    </div>)
                                                    : null}
                                                {data?.blog ? (
                                                    <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                        <Tooltip placement="right" title="Блог">
                                                            <span style={{ display: "flex", alignItems: "center" }}>
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
                                                    <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                        <img src={FollowersImage} style={{ height: 24, marginRight: 6, marginLeft: 2 }} /> {data?.followers_count} подписчиков
                                                    </div>)
                                                    : null}
                                                {data?.following_count != null ? (
                                                    <div style={{ textAlign: "left", display: "flex", color: "white", fontSize: 20, fontWeight: 600, alignItems: "center" }}>
                                                        <img src={SubscribesImage} style={{ height: 24, marginRight: 8 }} /> {data?.following_count} подписок
                                                    </div>)
                                                    : null}
                                            </Space>
                                            {(data?.email || data?.location || data?.twitter_username) && data?.bio ?
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
                                    <Col span={16} style={{ display: "flex", justifyContent: "flex-start", alignItems: "flex-start", backgroundColor: '#12171F', padding: 20 }}>
                                        {data?.repositories && data.repositories.length > 0 ? (
                                            <div style={{ width: "100%" }}>
                                                <div style={{ color: "white", fontSize: 28, fontWeight: 700, marginBottom: 20 }}>
                                                    Репозитории ({data.repositories.length})
                                                </div>
                                                <List
                                                    dataSource={data.repositories}
                                                    pagination={{
                                                        pageSize: 6,
                                                        showSizeChanger: false,
                                                        align: 'center',
                                                        position: 'bottom',
                                                        showLessItems: false
                                                    }}
                                                    renderItem={(repo) => (
                                                        <List.Item
                                                            style={{
                                                                backgroundColor: "#1C232F",
                                                                borderRadius: 15,
                                                                marginBottom: 15,
                                                                padding: 20,
                                                                border: "none",
                                                                cursor: "pointer",
                                                                transition: "0.3s"
                                                            }}
                                                            onClick={() => {
                                                                navigate(`/git_result?stroke=${encodeURIComponent(repo.html_url)}`);
                                                            }}
                                                            onMouseEnter={(e) => {
                                                                e.currentTarget.style.backgroundColor = "#262E3B";
                                                            }}
                                                            onMouseLeave={(e) => {
                                                                e.currentTarget.style.backgroundColor = "#1C232F";
                                                            }}
                                                        >
                                                            <div style={{ width: "100%" }}>
                                                                <div style={{ display: "flex", alignItems: "flex-start", marginBottom: 10 }}>
                                                                    <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", flex: 1 }}>
                                                                        <div style={{ color: "white", fontSize: 24, fontWeight: 600, display: "flex", alignItems: "center" }}>
                                                                            {repo.name} {repo.languages && repo.languages.length > 0 && (
                                                                                <div style={{ display: "flex", gap: 4, flexWrap: "wrap", marginLeft: 5 }}>
                                                                                    {repo.languages
                                                                                        .slice(0, 8)
                                                                                        .filter(lang => languageIcons[lang.language])
                                                                                        .map((lang, idx) => (
                                                                                            <Tooltip key={idx} title={lang.language} placement="top">
                                                                                                <img
                                                                                                    src={languageIcons[lang.language]}
                                                                                                    alt={lang.language}
                                                                                                    style={{
                                                                                                        height: 22,
                                                                                                        width: 22,
                                                                                                        objectFit: "contain",
                                                                                                        cursor: "pointer"
                                                                                                    }}
                                                                                                />
                                                                                            </Tooltip>
                                                                                        ))
                                                                                    }
                                                                                </div>
                                                                            )}
                                                                        </div>
                                                                        {repo.description && (
                                                                            <div style={{ color: "white", fontSize: 14, marginTop: 4, textAlign: "left" }}>
                                                                                {repo.description}
                                                                            </div>
                                                                        )}
                                                                    </div>
                                                                    <div style={{ color: "#8EAEE3", fontSize: 14, whiteSpace: "nowrap" }}>
                                                                        ID: {repo.git_id}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </List.Item>
                                                    )}
                                                />
                                            </div>
                                        ) : (
                                            <div style={{ color: "#8EAEE3", fontSize: 18 }}>
                                                Репозитории не найдены
                                            </div>
                                        )}
                                    </Col>
                                </Row>
                                <Row>
                                    <Col span={8} style={{ backgroundColor: '#1C232F', borderRadius: "0 0 0 25px", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20, width: 250 }}>
                                    </Col>
                                    <Col span={16} style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", backgroundColor: '#12171F', borderRadius: "0 0 25px 0" }}>
                                    </Col>
                                </Row>
                            </div>
                        </Space>
                    ) : (
                        <Space direction="vertical" style={{ width: '90%', display: loading ? "none" : "block" }}>
                            <Row style={{ backgroundColor: "#1C232F", borderRadius: 25 }} align={"middle"} justify={"center"}>
                                <Col span={8} style={{ borderRadius: "25px 0 0 25px", display: "flex", justifyContent: "flex-start", alignItems: "center", padding: 20 }}>
                                    <Space direction="vertical" size={0}>
                                        {data?.owner_avatar_url && data?.owner_login ? (
                                            <div style={{ color: "white", fontSize: 20, fontWeight: 600, display: "flex", alignItems: "center", gap: 5, cursor: "pointer" }} onClick={() => {
                                                                navigate(`/git_result?stroke=${encodeURIComponent(data.owner_login)}`);
                                                            }}>
                                                <div style={{display: "flex"}}><img src={data.owner_avatar_url} alt="avatar" style={{ height: 34, borderRadius: '30%', display: "block", marginRight: 5 }} />
                                                {data.owner_login}</div>
                                            </div>
                                        ) : (
                                            <Spin indicator={<LoadingOutlined />} />
                                        )}
                                        {data?.name && (
                                            <div style={{ color: "white", fontSize: 26, fontWeight: 700, display: "flex", alignItems: "center", gap: 5 }}>
                                                {data.name}
                                            </div>
                                        )
                                        }
                                        {data?.created_at && data?.updated_at && data?.pushed_at ? (
                                            <Space size={0} direction="vertical" style={{ display: "flex", alignItems: "flex-start", justifyContent: "flex-start" }}>
                                                <div style={{ color: "#8EAEE3", fontSize: 14, fontWeight: 600, height: 18 }}>
                                                    Последнее обновление: {formatDate(data.updated_at)}
                                                </div>
                                                <div style={{ color: "#8EAEE3", fontSize: 14, fontWeight: 600, height: 18 }}>
                                                    Создан: {formatDate(data.created_at)}
                                                </div>
                                                <div style={{ color: "#8EAEE3", fontSize: 14, fontWeight: 600, height: 18 }}>
                                                    Последний пуш: {formatDate(data.pushed_at)}
                                                </div>
                                            </Space>
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
                                        <Tooltip placement="top" title={<span>{"Последний запрос: "}<br />{lastUpdate ? formatDateTime(lastUpdate) : "Только что"}</span>}>
                                            <span><ReloadButton style={{ height: 60, width: 60, borderRadius: 20 }} onClick={getData}></ReloadButton></span>
                                        </Tooltip>
                                    </div>
                                </Col>
                            </Row>
                            <Row>
                                <Col style={{ display: "flex", justifyContent: "center", width: "100%" }}>
                                    <div style={{ height: 60, backgroundColor: "#262E3B", marginTop: -20, borderRadius: 16, color: "white", fontWeight: 600, fontSize: 20, display: "flex", alignItems: "center", justifyContent: "center", padding: 5 }}>
                                        <Tooltip placement="top" title="ID на GitHub">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={IdImage} style={{ height: 22 }} />{data?.git_id}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Основная ветка">
                                            <div style={{ display: "flex", alignItems: "center", gap: 1, margin: 10 }}>
                                                <img src={BranchImage} style={{ height: 22 }} />{data?.default_branch}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Количество звезд">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={StarsImage} style={{ height: 22 }} />{data?.stars}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Форки">
                                            <div style={{ display: "flex", alignItems: "center", gap: 1, margin: 10 }}>
                                                <img src={ForksImage} style={{ height: 22 }} />{data?.forks}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Размер в KB">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={CodeImage} style={{ height: 22 }} />{data?.repo_size}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Открытых вопросов">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={IssuesImage} style={{ height: 22 }} />{data?.open_issues}
                                            </div>
                                        </Tooltip>
                                        <Tooltip placement="top" title="Кол-во подписчиков">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={FollowersImage} style={{ height: 22 }} />{data?.subscribers_count ? data?.subscribers_count : 0}
                                            </div>
                                        </Tooltip>
                                        {data?.license.length > 0 && (
                                            <Tooltip placement="top" title="Лицензия">
                                            <div style={{ display: "flex", alignItems: "center", gap: 3, margin: 10 }}>
                                                <img src={LicenseImage} style={{height: 26}}></img>{data.license[0].license_name}
                                            </div>
                                        </Tooltip>
                                        )}
                                    </div>
                                </Col>
                            </Row>
                            {data?.description && (
                                <Row style={{backgroundColor: "#1C232F", borderRadius: 25, marginTop: -20, color: "white", paddingTop: 40, paddingBottom: 40, paddingLeft: 20, paddingRight: 20, textAlign: "left", fontWeight: 600}}>
                                    <Col>
                                        <span style={{fontSize: 18}}>{data.description}</span>
                                    </Col>
                                </Row>
                            )}
                            <Row style={{ backgroundColor: "#1C232F", borderRadius: 25, marginTop: data?.description ? 20 : -20, padding: 30 }}>
                                <Col span={12} style={{display: "flex", alignContent: "center", justifyContent: "center"}}>
                                    {data?.commits && data.commits.length > 0 ? (
                                        <div style={{ width: "90%" }}>
                                            <div style={{ color: "white", fontSize: 28, fontWeight: 700, marginBottom: 20 }}>
                                                Коммиты ({data.commits.length})
                                            </div>
                                            <List
                                                dataSource={data.commits}
                                                pagination={{
                                                    pageSize: 6,
                                                    showSizeChanger: false,
                                                    align: 'center',
                                                    position: 'bottom',
                                                    showLessItems: false
                                                }}
                                                renderItem={(commit) => (
                                                    <List.Item
                                                        style={{
                                                            backgroundColor: "#262E3B",
                                                            borderRadius: 15,
                                                            marginBottom: 15,
                                                            padding: 20,
                                                            border: "none",
                                                            cursor: "pointer",
                                                            transition: "0.3s"
                                                        }}
                                                        onClick={() => {
                                                            window.open(commit.url, '_blank');
                                                        }}
                                                        onMouseEnter={(e) => {
                                                            e.currentTarget.style.backgroundColor = "#354052";
                                                        }}
                                                        onMouseLeave={(e) => {
                                                            e.currentTarget.style.backgroundColor = "#262E3B";
                                                        }}
                                                    >
                                                        <div style={{ width: "100%", display: "flex", alignItems: "center", gap: 15 }}>
                                                            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", flex: 1 }}>
                                                                <div style={{ color: "white", fontSize: 18, fontWeight: 600, marginBottom: 5, display: "flex", alignItems: "center" }}>
                                                                    {commit.author_avatar_url && <img src={commit.author_avatar_url} style={{height: 30, borderRadius: 10, marginRight: 10}}/>}
                                                                    Автор: {commit.author_login ? commit.author_login : "Неизвестно"}
                                                                </div>
                                                                <div style={{ color: "#8EAEE3", fontSize: 14, fontFamily: "monospace" }}>
                                                                    SHA: {commit.sha}
                                                                </div>
                                                            </div>
                                                            <div style={{ color: "#8EAEE3", fontSize: 14, whiteSpace: "nowrap" }}>
                                                                {formatDateTime(commit.commit_date)}
                                                            </div>
                                                        </div>
                                                    </List.Item>
                                                )}
                                            />
                                        </div>
                                    ) : (
                                        <div style={{ color: "#8EAEE3", fontSize: 18 }}>
                                            Коммиты не найдены
                                        </div>
                                    )}

                                </Col>
                                <Col span={12}>
                                    {data && <LanguagesDiagram languages={data?.languages} />}
                                </Col>
                            </Row>
                        </Space>
                    )}

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

                    .ant-pagination-item{
                        background-color: transparent !important;
                        color: #8EAEE3 !important;
                        border: 1px solid #8EAEE3 !important;
                        transition: 0.3s;
                    }
                    
                    .ant-pagination-item:hover{
                        background-color: #8EAEE3 !important;
                    }
                    
                    .ant-pagination-item:hover a{
                        color: black !important;
                    }

                    .ant-pagination-item a{
                        color: #8EAEE3 !important;
                    }

                    .ant-pagination-item-link {
                      color: #8EAEE3 !important;
                    }

                    .ant-pagination-item-link,
                    .ant-pagination-item-link-icon,
                    .ant-pagination-item-ellipsis {
                      color: #8EAEE3!important;
                    }
                    `}</style>
            </Content></>
    )
}

export default GitRequestResultComp;