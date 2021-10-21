import React from 'react';
import ReactDOM from 'react-dom';
import { BrowserRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';

import App from './App';
import store from './app/store';
// Does a lot of styling
import 'antd/dist/antd.css';

// the provider <> in this is what is connecting our app to our redux store
ReactDOM.render(
    <Router>
        <Provider store={store}>
            <App />
        </Provider>
    </Router>,
    document.getElementById('root')
);   