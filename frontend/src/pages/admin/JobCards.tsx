import { useEffect, useState } from 'react';
import { Clipboard, Search, MoreVertical, Trash2, Eye } from 'lucide-react';
import { toast } from 'sonner';

export function AdminJobCards() {
  const [jobCards, setJobCards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedJobCard, setSelectedJobCard] = useState<any>(null);

  useEffect(() => {
    loadJobCards();
  }, [statusFilter]);

  const loadJobCards = async () => {
    try {
      setLoading(true);
      const url = statusFilter
        ? `http://localhost:3001/api/admin/job-cards/status/${statusFilter}`
        : 'http://localhost:3001/api/admin/job-cards';
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      const data = await response.json();
      setJobCards(data.data || []);
    } catch (error) {
      console.error('Failed to load job cards:', error);
      toast.error('Failed to load job cards');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (id: number, newStatus: string) => {
    try {
      const response = await fetch(`http://localhost:3001/api/admin/job-cards/${id}/status/${newStatus}`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      });
      
      if (response.ok) {
        toast.success('Status updated successfully');
        loadJobCards();
        if (selectedJobCard?.id === id) {
          setSelectedJobCard(null);
        }
      } else {
        toast.error('Failed to update status');
      }
    } catch (error) {
      toast.error('Error updating status');
    }
  };

  const handleDeleteJobCard = async (id: number) => {
    if (confirm('Are you sure you want to delete this job card?')) {
      try {
        const response = await fetch(`http://localhost:3001/api/admin/job-cards/${id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
        });
        
        if (response.ok) {
          toast.success('Job card deleted successfully');
          loadJobCards();
          setSelectedJobCard(null);
        } else {
          toast.error('Failed to delete job card');
        }
      } catch (error) {
        toast.error('Error deleting job card');
      }
    }
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      NEW: 'bg-gray-50 text-gray-700 border-gray-200',
      IN_PROGRESS: 'bg-blue-50 text-blue-700 border-blue-200',
      COMPLETED: 'bg-green-50 text-green-700 border-green-200',
      PAUSED: 'bg-yellow-50 text-yellow-700 border-yellow-200',
      CANCELLED: 'bg-red-50 text-red-700 border-red-200',
    };
    return colors[status] || 'bg-gray-50 text-gray-700 border-gray-200';
  };

  const getPriorityColor = (priority: string) => {
    const colors: Record<string, string> = {
      LOW: 'text-gray-600',
      NORMAL: 'text-blue-600',
      HIGH: 'text-orange-600',
      URGENT: 'text-red-600',
    };
    return colors[priority] || 'text-gray-600';
  };

  const filteredJobCards = jobCards.filter(
    (card) =>
      card.jobNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      card.serviceType.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (card.mechanicName && card.mechanicName.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
          <p className="mt-4 text-black/70">Loading job cards...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#ff5d2e] rounded-lg flex items-center justify-center">
            <Clipboard className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-black">Job Cards Management</h1>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-3 w-5 h-5 text-black/40" />
          <input
            type="text"
            placeholder="Search by job number, service type, or mechanic..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 bg-white border border-black/10 rounded-lg text-sm focus:outline-none focus:border-[#ff5d2e]"
        >
          <option value="">All Status</option>
          <option value="NEW">New</option>
          <option value="IN_PROGRESS">In Progress</option>
          <option value="COMPLETED">Completed</option>
          <option value="PAUSED">Paused</option>
          <option value="CANCELLED">Cancelled</option>
        </select>
      </div>

      {/* Job Cards Table */}
      <div className="bg-white rounded-lg border border-black/10 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-black/5 border-b border-black/10">
            <tr>
              <th className="px-6 py-3 text-left font-semibold text-black">Job Card #</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Service Type</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Mechanic</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Bay</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Status</th>
              <th className="px-6 py-3 text-left font-semibold text-black">Priority</th>
              <th className="px-6 py-3 text-right font-semibold text-black">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredJobCards.length > 0 ? (
              filteredJobCards.map((card) => (
                <tr key={card.id} className="border-t border-black/10 hover:bg-black/2">
                  <td className="px-6 py-3 font-medium text-black">{card.jobNumber}</td>
                  <td className="px-6 py-3 text-black/70">{card.serviceType}</td>
                  <td className="px-6 py-3 text-black">{card.mechanicName || 'Unassigned'}</td>
                  <td className="px-6 py-3 text-black">{card.bayNumber || 'Unassigned'}</td>
                  <td className="px-6 py-3">
                    <select
                      value={card.status}
                      onChange={(e) => handleUpdateStatus(card.id, e.target.value)}
                      className={`px-2 py-1 rounded text-xs font-medium cursor-pointer border ${getStatusColor(card.status)}`}
                    >
                      <option value="NEW">New</option>
                      <option value="IN_PROGRESS">In Progress</option>
                      <option value="COMPLETED">Completed</option>
                      <option value="PAUSED">Paused</option>
                      <option value="CANCELLED">Cancelled</option>
                    </select>
                  </td>
                  <td className={`px-6 py-3 font-medium ${getPriorityColor(card.priority)}`}>
                    {card.priority}
                  </td>
                  <td className="px-6 py-3">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setSelectedJobCard(card)}
                        className="p-2 hover:bg-black/5 rounded-lg"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4 text-black/60" />
                      </button>
                      <div className="relative group">
                        <button className="p-2 hover:bg-black/5 rounded-lg">
                          <MoreVertical className="w-4 h-4 text-black/60" />
                        </button>
                        <div className="absolute right-0 top-full hidden group-hover:flex flex-col bg-white border border-black/10 rounded-lg shadow-lg">
                          <button
                            onClick={() => handleDeleteJobCard(card.id)}
                            className="px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                          >
                            <Trash2 className="w-4 h-4" />
                            Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-black/60">
                  No job cards found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Detailed View Modal */}
      {selectedJobCard && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-2xl font-bold text-black">{selectedJobCard.jobNumber}</h2>
                <p className="text-black/60">{selectedJobCard.serviceType}</p>
              </div>
              <button
                onClick={() => setSelectedJobCard(null)}
                className="text-black/60 hover:text-black text-2xl"
              >
                ×
              </button>
            </div>

            <div className="grid grid-cols-2 gap-6 mb-6">
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Status</p>
                <p className={`text-lg font-medium ${
                  selectedJobCard.status === 'COMPLETED' ? 'text-green-600' :
                  selectedJobCard.status === 'IN_PROGRESS' ? 'text-blue-600' :
                  'text-black'
                }`}>
                  {selectedJobCard.status}
                </p>
              </div>
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Priority</p>
                <p className={`text-lg font-medium ${getPriorityColor(selectedJobCard.priority)}`}>
                  {selectedJobCard.priority}
                </p>
              </div>
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Assigned Mechanic</p>
                <p className="text-black">{selectedJobCard.mechanicName || 'Unassigned'}</p>
              </div>
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Service Bay</p>
                <p className="text-black">{selectedJobCard.bayNumber || 'Unassigned'}</p>
              </div>
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Estimated Hours</p>
                <p className="text-black">{selectedJobCard.estimatedHours || '-'} hours</p>
              </div>
              <div>
                <p className="text-sm font-semibold text-black/60 mb-1">Estimated Cost</p>
                <p className="text-black">
                  {selectedJobCard.estimatedCost ? `LKR ${selectedJobCard.estimatedCost}` : '-'}
                </p>
              </div>
            </div>

            {selectedJobCard.description && (
              <div className="mb-6 p-4 bg-black/2 rounded-lg">
                <p className="text-sm font-semibold text-black/60 mb-2">Description</p>
                <p className="text-black">{selectedJobCard.description}</p>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setSelectedJobCard(null)}
                className="flex-1 px-4 py-2 bg-black/5 text-black rounded-lg hover:bg-black/10 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
