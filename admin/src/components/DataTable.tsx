import { ChevronLeft, ChevronRight, Search } from 'lucide-react'
import LoadingSpinner from './LoadingSpinner'
import EmptyState from './EmptyState'

export interface Column<T> {
  key: string
  label: string
  render?: (row: T) => React.ReactNode
  sortable?: boolean
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  page?: number
  totalPages?: number
  onPageChange?: (page: number) => void
  searchPlaceholder?: string
  onSearch?: (query: string) => void
}

export default function DataTable<T extends Record<string, unknown>>({
  columns,
  data,
  loading = false,
  page = 1,
  totalPages = 1,
  onPageChange,
  searchPlaceholder = 'Search...',
  onSearch,
}: DataTableProps<T>) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <LoadingSpinner />
      </div>
    )
  }

  return (
    <div>
      {onSearch && (
        <div className="mb-4 flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2">
          <Search size={18} className="text-slate-400" />
          <input
            type="text"
            placeholder={searchPlaceholder}
            onChange={(e) => onSearch(e.target.value)}
            className="flex-1 border-0 bg-transparent text-sm outline-none placeholder:text-slate-400"
          />
        </div>
      )}

      {data.length === 0 ? (
        <EmptyState />
      ) : (
        <div className="overflow-hidden rounded-xl bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50">
                {columns.map((col) => (
                  <th key={col.key} className="px-4 py-3 font-medium text-slate-600">
                    {col.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.map((row, i) => (
                <tr key={i} className="border-b border-slate-50 hover:bg-slate-50">
                  {columns.map((col) => (
                    <td key={col.key} className="px-4 py-3 text-slate-700">
                      {col.render ? col.render(row) : String(row[col.key] ?? '')}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>

          {onPageChange && totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
              <span className="text-sm text-slate-500">
                Page {page} of {totalPages}
              </span>
              <div className="flex gap-2">
                <button
                  onClick={() => onPageChange(page - 1)}
                  disabled={page <= 1}
                  className="rounded-lg border border-slate-200 p-1.5 text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                >
                  <ChevronLeft size={18} />
                </button>
                <button
                  onClick={() => onPageChange(page + 1)}
                  disabled={page >= totalPages}
                  className="rounded-lg border border-slate-200 p-1.5 text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                >
                  <ChevronRight size={18} />
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
