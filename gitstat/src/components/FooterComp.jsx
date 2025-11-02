import { Layout } from 'antd';

const { Footer } = Layout;

function FooterComp() {
    return (
        <Footer style={{ textAlign: 'center', backgroundColor: '#12171F', color: '#fff', fontWeight: '600' }}>
            Git Stat ©{new Date().getFullYear()} Created by German Statko
        </Footer>
    )
}

export default FooterComp;