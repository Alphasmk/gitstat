import { useState } from 'react';
import { Breadcrumb, Layout, Menu, theme } from 'antd';
import FooterComp from './FooterComp';
import QueryContentComp from './QueryContentComp';
import HeaderComp from './HeaderComp';

const { Header, Content, Footer } = Layout;


function MainPage() {
  return (
    <Layout style={{ minHeight: '50vh', width: '100vw' }}>
      <HeaderComp/>
      <QueryContentComp/>
      <FooterComp/>
    </Layout>
  );
}

export default MainPage;
