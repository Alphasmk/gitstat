import { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import LoginComp from './components/loginComp'
import MainPage from './components/MainPage';
import axios from 'axios';
import './App.css'

const ProtectedMainPage = () => {
  const navigate = useNavigate();

  useEffect(() => {
    const checkAuth = async () => {
      try {
        await axios.get('http://localhost:8000/users/me', {
        headers: { 'Content-Type': 'application/json' },
        withCredentials: true
      });
      } catch (error) {
        navigate('/login');
      }
    };
    checkAuth();
  }, [navigate]);

  return <MainPage />;
}

const ProtectedLoginPage = () => {
  const navigate = useNavigate();

  useEffect(() => {
    const checkAuth = async () => {
      try {
        await axios.get('http://localhost:8000/users/me', {
        headers: { 'Content-Type': 'application/json' },
        withCredentials: true
      });
        navigate('/');
      }
      catch (error) {
      }
    };
    checkAuth();
  }, [navigate]);

  return <LoginComp />;
}


function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<ProtectedMainPage/>} />
        <Route path="/login" element={<ProtectedLoginPage />} />
      </Routes>
    </Router>
  );
}

export default App

//<Route path="/" element={<Navigate to="/login" replace />} />