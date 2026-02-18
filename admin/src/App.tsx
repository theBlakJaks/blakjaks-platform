import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
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
        <Route path="/users" element={<ComingSoon />} />
        <Route path="/qr-codes" element={<ComingSoon />} />
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
