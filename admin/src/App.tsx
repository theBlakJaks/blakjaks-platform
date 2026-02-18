import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import UserDetail from './pages/UserDetail'
import QRCodes from './pages/QRCodes'
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
        <Route path="/orders" element={<ComingSoon />} />
        <Route path="/comps" element={<ComingSoon />} />
        <Route path="/affiliates" element={<ComingSoon />} />
        <Route path="/social" element={<ComingSoon />} />
        <Route path="/governance" element={<ComingSoon />} />
        <Route path="/treasury" element={<ComingSoon />} />
        <Route path="/analytics" element={<ComingSoon />} />
        <Route path="/settings" element={<ComingSoon />} />
      </Route>
    </Routes>
  )
}
