import { useState, useEffect } from "react";
import { LoadingOutlined } from '@ant-design/icons';
import { Spin, Layout, Flex } from "antd";
import { useLocation } from 'react-router-dom';

const { Content } = Layout;

function GitRequestResultComp() {
    const [loading, setLoading] = useState(true);
    const [data, setData] = useState(null);
    const { search } = useLocation();
    useEffect(() => {
        const params = new URLSearchParams(search);

        const stroke = params.get('stroke');
        fetch(`http://localhost:8000/git_info?stroke=${encodeURIComponent(stroke)}`, {
            method: 'GET',
            credentials: 'include'
        })
            .then(resp => resp.json())
            .then(data => {
                setData(data);
                setLoading(false);
            })
            .catch(err => {
                console.error(err);
                setLoading(false);
            });
    }, []);
    return (
        <Content style={{ padding: '0 0px', flex: 1 }}>
            <div
                className='bg-container'
            >
                <Flex align="center" gap="middle">
                    <Spin spinning={loading} indicator={<LoadingOutlined style={{ fontSize: 48 }} spi />}>
                        <div id="content" style={{color: 'white'}}>
                            {data ? (
                                <pre>{JSON.stringify(data, null, 2)}</pre>
                            ) : (
                                !loading && <p>Нет данных</p>
                            )}
                        </div>
                    </Spin>
                </Flex>
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
                    `}</style>
        </Content>
    )
}

export default GitRequestResultComp;