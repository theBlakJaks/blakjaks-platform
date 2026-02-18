import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import UserDetail from './pages/UserDetail'
import QRCodes from './pages/QRCodes'
import Orders from './pages/Orders'
import OrderDetail from './pages/OrderDetail'
import Comps from './pages/Comps'
import SocialModeration from './pages/SocialModeration'
import Governance from './pages/Governance'
import Affiliates from './pages/Affiliates'
import Treasury from './pages/Treasury'
import ComingSoon from './pages/ComingSoon'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<Dashboard />} />
        <Route path="/users" element={<Users />} />
        <Route path="/users/:id" element={<UserDetail />} />
        <Route path="/qr-codes" element={<QRCodes />} />
        <Route path="/orders" element={<Orders />} />
        <Route path="/orders/:id" element={<OrderDetail />} />
        <Route path="/comps" element={<Comps />} />
        <Route path="/affiliates" element={<Affiliates />} />
        <Route path="/social" element={<SocialModeration />} />
        <Route path="/governance" element={<Governance />} />
        <Route path="/treasury" element={<Treasury />} />
        <Route path="/analytics" element={<ComingSoon />} />
        <Route path="/settings" element={<ComingSoon />} />
      </Route>
    </Routes>
  )
}
