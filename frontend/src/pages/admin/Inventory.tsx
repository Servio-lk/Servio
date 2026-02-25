import { useEffect, useState } from 'react';
import { adminApi } from '../../services/adminApi';
import { Package, Plus, Search, Edit, Trash2, Filter, AlertTriangle, Layers } from 'lucide-react';
import { toast } from 'sonner';

export function AdminInventory() {
    const [inventory, setInventory] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        loadInventory();
    }, []);

    const loadInventory = async () => {
        try {
            setLoading(true);
            const data = await adminApi.getAllInventory();
            setInventory(data || []);
        } catch (error) {
            console.error('Failed to load inventory:', error);
            toast.error('Failed to load inventory');
        } finally {
            setLoading(false);
        }
    };

    const filteredInventory = inventory.filter(item =>
        item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.description?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff5d2e] mx-auto"></div>
                    <p className="mt-4 text-black/70">Loading inventory...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="flex flex-col gap-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-black">Inventory Management</h1>
                    <p className="text-black/70 mt-1">Manage parts, oil, and other service items</p>
                </div>
                <button className="flex items-center gap-2 px-4 py-2 bg-[#ff5d2e] text-white rounded-lg hover:bg-[#e54d1e] transition-colors shadow-lg shadow-[#ff5d2e]/20">
                    <Plus className="h-4 w-4" />
                    <span>Add New Item</span>
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-2">
                <div className="bg-white p-4 rounded-xl border border-black/5 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-blue-50 text-blue-600 rounded-lg">
                            <Layers className="h-5 w-5" />
                        </div>
                        <div>
                            <p className="text-xs text-black/50 font-medium">Total Items</p>
                            <p className="text-xl font-bold text-black">{inventory.length}</p>
                        </div>
                    </div>
                </div>
                <div className="bg-white p-4 rounded-xl border border-black/5 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-yellow-50 text-yellow-600 rounded-lg">
                            <AlertTriangle className="h-5 w-5" />
                        </div>
                        <div>
                            <p className="text-xs text-black/50 font-medium">Low Stock Items</p>
                            <p className="text-xl font-bold text-black">
                                {inventory.filter(i => i.quantity <= (i.minStockLevel || 0)).length}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl border border-black/5 shadow-sm overflow-hidden">
                {/* Toolbar */}
                <div className="p-4 border-b border-black/5 flex flex-col sm:flex-row gap-4 justify-between items-center">
                    <div className="relative w-full sm:w-96">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search inventory..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="w-full pl-10 pr-4 py-2 bg-gray-50 border-transparent focus:bg-white focus:border-[#ff5d2e] focus:ring-0 rounded-lg transition-all text-sm"
                        />
                    </div>
                    <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-600 hover:text-black hover:bg-gray-50 rounded-lg transition-colors">
                        <Filter className="h-4 w-4" />
                        Filter
                    </button>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-gray-50/50 border-b border-black/5">
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Item Name</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Stock Level</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Unit</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Unit Price</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {filteredInventory.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                                        <div className="bg-gray-50 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                                            <Package className="h-8 w-8 text-gray-400" />
                                        </div>
                                        <p className="text-lg font-medium text-black">No items found</p>
                                        <p className="text-sm text-gray-500">Try adjusting your search or add a new item.</p>
                                    </td>
                                </tr>
                            ) : (
                                filteredInventory.map((item) => (
                                    <tr key={item.id} className="hover:bg-gray-50/50 transition-colors group">
                                        <td className="px-6 py-4">
                                            <div>
                                                <p className="font-semibold text-black text-sm">{item.name}</p>
                                                <p className="text-xs text-gray-500 line-clamp-1 max-w-[200px]">{item.description}</p>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col gap-1">
                                                <span className={`text-sm font-bold ${item.quantity <= (item.minStockLevel || 0) ? 'text-red-500' : 'text-black'}`}>
                                                    {item.quantity}
                                                </span>
                                                {item.minStockLevel && (
                                                    <span className="text-[10px] text-gray-400 uppercase tracking-wider">
                                                        Min: {item.minStockLevel}
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-500 uppercase">
                                            {item.unit}
                                        </td>
                                        <td className="px-6 py-4 text-sm font-medium text-black">
                                            {item.price ? `Rs. ${item.price.toLocaleString()}` : '-'}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium transition-colors ${item.quantity <= 0
                                                    ? 'bg-red-50 text-red-700 border border-red-200'
                                                    : item.quantity <= (item.minStockLevel || 0)
                                                        ? 'bg-yellow-50 text-yellow-700 border border-yellow-200'
                                                        : 'bg-green-50 text-green-700 border border-green-200'
                                                }`}>
                                                <div className={`w-1.5 h-1.5 rounded-full ${item.quantity <= 0 ? 'bg-red-500' : item.quantity <= (item.minStockLevel || 0) ? 'bg-yellow-500' : 'bg-green-500'
                                                    }`} />
                                                {item.quantity <= 0 ? 'Out of Stock' : item.quantity <= (item.minStockLevel || 0) ? 'Low Stock' : 'In Stock'}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button
                                                    className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                    title="Edit"
                                                >
                                                    <Edit className="h-4 w-4" />
                                                </button>
                                                <button
                                                    className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                    title="Delete"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                <div className="p-4 border-t border-black/5 bg-gray-50/50 flex items-center justify-between text-xs text-gray-500">
                    <span>Showing {filteredInventory.length} results</span>
                </div>
            </div>
        </div>
    );
}
