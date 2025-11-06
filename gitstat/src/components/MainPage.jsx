import { useState } from 'react';
import { Breadcrumb, Layout, Menu, theme } from 'antd';
import FooterComp from './FooterComp';
import GitRequestContentComp from './GitRequestContentComp';
import HeaderComp from './HeaderComp';

const { Header, Content, Footer } = Layout;


function MainPage() {
  return (
    <GitRequestContentComp/>
  );
}

export default MainPage;
