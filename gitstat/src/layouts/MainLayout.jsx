import { Outlet } from 'react-router-dom';
import HeaderComp from '../components/HeaderComp';
import FooterComp from '../components/FooterComp';
import { Layout } from 'antd';

const { Content } = Layout;

function MainLayout() {
    return(
        <Layout style={{ minHeight: '50vh', width: '100vw' }}>
            <HeaderComp/>
                <Content style={{ padding: '0 0px', flex: 1 }}>
                    <Outlet/>
                </Content>
            <FooterComp/>
        </Layout>
    )
}

export default MainLayout;