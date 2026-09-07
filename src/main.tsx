import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import { ErrorBoundary } from './components/common/ErrorBoundary';
import { ToastProvider } from './context/ToastContext';
import { ToastContainer } from './components/common/Toast';
import './styles/index.css';
import './styles/components.css';
import './styles/study-modes.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <ToastProvider>
        <App />
        <ToastContainer />
      </ToastProvider>
    </ErrorBoundary>
  </React.StrictMode>,
);
