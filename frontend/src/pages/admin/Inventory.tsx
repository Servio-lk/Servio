import { useState, useEffect } from 'react';
import { PackageSearch, PackageOpen, AlertTriangle, Filter, Plus, ArrowDownToLine, ArrowUpFromLine, MoreVertical, Search, Edit2, Trash2, X } from 'lucide-react';
import { inventoryApi } from '@/services/inventoryApi';
import type { InventoryItem, InventoryItemRequest, StockUpdateRequest, StockTransaction } from '@/services/inventoryApi';

export function AdminInventory() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modals state
  const [addItemModalOpen, setAddItemModalOpen] = useState(false);
  const [editItemModalOpen, setEditItemModalOpen] = useState(false);
  const [stockModalOpen, setStockModalOpen] = useState(false);
  const [consumeModalOpen, setConsumeModalOpen] = useState(false);
  const [historyModalOpen, setHistoryModalOpen] = useState(false);

  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null);
  const [transactions, setTransactions] = useState<StockTransaction[]>([]);

  // Search and filter
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState('All');

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const res = await inventoryApi.getAllItems();
      if (res.success && res.data) {
        setItems(res.data);
      } else {
        setError(res.message || 'Failed to fetch inventory');
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const fetchHistory = async (itemId: number) => {
    try {
      const res = await inventoryApi.getTransactionHistory(itemId);
      if (res.success && res.data) {
        setTransactions(res.data);
      }
    } catch (err) {
      console.error('Failed to fetch history', err);
    }
  };

  const openStockModal = (item: InventoryItem) => {
    setSelectedItem(item);
    setStockModalOpen(true);
  };

  const openHistoryModal = (item: InventoryItem) => {
    setSelectedItem(item);
    fetchHistory(item.id);
    setHistoryModalOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm('Are you sure you want to delete this item?')) {
      try {
        await inventoryApi.deleteItem(id);
        fetchItems();
      } catch (err) {
        console.error('Failed to delete', err);
      }
    }
  };

  // Derived metrics
  const totalItems = items.length;
  const lowStockCount = items.filter(i => i.lowStock).length;
  const totalValue = items.reduce((acc, curr) => acc + (curr.costPerUnit * curr.currentStock), 0);
  
  const categories = ['All', ...Array.from(new Set(items.map(i => i.category)))];

  const filteredItems = items.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = filterCategory === 'All' || item.category === filterCategory;
    return matchesSearch && matchesCategory;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#ff5d2e]"></div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 max-w-[1400px] mx-auto w-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-black">Inventory POS</h1>
          <p className="text-sm text-black/60 mt-1">Manage stock, parts and consumables</p>
        </div>
        <button
          onClick={() => { setSelectedItem(null); setAddItemModalOpen(true); }}
          className="bg-[#ff5d2e] hover:bg-[#ff5d2e]/90 text-white px-4 py-2 rounded-lg font-medium transition-colors flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Item
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-red-600 p-4 rounded-lg flex items-center gap-2">
          <AlertTriangle className="w-5 h-5" />
          {error}
        </div>
      )}

      {/* Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white border border-black/5 p-4 rounded-xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center text-blue-500">
            <PackageSearch className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-black/60 font-medium">Total SKUs</p>
            <p className="text-2xl font-bold text-black">{totalItems}</p>
          </div>
        </div>
        <div className="bg-white border border-black/5 p-4 rounded-xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-lg bg-red-50 flex items-center justify-center text-red-500">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-black/60 font-medium">Low Stock Alerts</p>
            <p className="text-2xl font-bold text-red-600">{lowStockCount}</p>
          </div>
        </div>
        <div className="bg-white border border-black/5 p-4 rounded-xl flex items-center gap-4 shadow-sm">
          <div className="w-12 h-12 rounded-lg bg-green-50 flex items-center justify-center text-green-500">
            <PackageOpen className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm text-black/60 font-medium">Total Inventory Value</p>
            <p className="text-2xl font-bold text-black">Rs. {totalValue.toLocaleString()}</p>
          </div>
        </div>
      </div>

      {/* Actions & Filters */}
      <div className="bg-white p-4 rounded-xl border border-black/5 flex flex-col md:flex-row gap-4 justify-between items-center shadow-sm">
        <div className="relative w-full md:w-96">
          <Search className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search items..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-gray-50 border-none rounded-lg focus:ring-2 focus:ring-[#ff5d2e] focus:bg-white outline-none transition-all"
          />
        </div>
        <div className="flex gap-2 w-full md:w-auto overflow-x-auto pb-2 md:pb-0 hide-scrollbar">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setFilterCategory(cat)}
              className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
                filterCategory === cat 
                  ? 'bg-black text-white' 
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-white border border-black/5 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-black/5">
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Item Details</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Stock Level</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Pricing (Rs)</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {filteredItems.map(item => (
                <tr key={item.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1">
                      <span className="font-semibold text-black">{item.name}</span>
                      <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full w-fit">
                        {item.category}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1">
                      <div className="flex items-center gap-2">
                        <span className={`text-lg font-bold ${item.lowStock ? 'text-red-600' : 'text-black'}`}>
                          {item.currentStock}
                        </span>
                        <span className="text-sm text-gray-500">/ {item.unit}s</span>
                      </div>
                      {item.lowStock && (
                        <span className="text-xs font-medium text-red-600 bg-red-50 px-2 py-0.5 rounded block w-fit">
                          Low Stock (Min: {item.minimumStock})
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col text-sm">
                      <span className="text-gray-500">Cost: {item.costPerUnit.toLocaleString()}</span>
                      <span className="font-medium text-black">Sell: {item.sellingPricePerUnit.toLocaleString()}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button 
                        onClick={() => openStockModal(item)}
                        className="p-2 text-[#ff5d2e] bg-[#ffe7df] hover:bg-[#ffd1c2] rounded-lg transition-colors flex items-center gap-1 text-sm font-medium"
                      >
                        <ArrowDownToLine className="w-4 h-4" />
                        Receive
                      </button>
                      <button 
                        onClick={() => { setSelectedItem(item); setConsumeModalOpen(true); }}
                        className="p-2 text-black bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors flex items-center gap-1 text-sm font-medium"
                      >
                        <ArrowUpFromLine className="w-4 h-4" />
                        Issue
                      </button>
                      <button 
                        onClick={() => openHistoryModal(item)}
                        title="View History"
                        className="p-2 text-gray-500 hover:text-black hover:bg-gray-100 rounded-lg transition-colors"
                      >
                        <MoreVertical className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => handleDelete(item.id)}
                        className="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredItems.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-8 text-center text-gray-500">
                    No items found matching your criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Item Modal */}
      {addItemModalOpen && (
        <AddItemModal 
          onClose={() => setAddItemModalOpen(false)} 
          onSuccess={() => { setAddItemModalOpen(false); fetchItems(); }} 
        />
      )}

      {/* Receive Stock Modal */}
      {stockModalOpen && selectedItem && (
        <ReceiveStockModal 
          item={selectedItem}
          onClose={() => { setStockModalOpen(false); setSelectedItem(null); }}
          onSuccess={() => { setStockModalOpen(false); fetchItems(); }}
        />
      )}

      {/* Consume/Issue Stock Modal */}
      {consumeModalOpen && selectedItem && (
        <ConsumeStockModal 
          item={selectedItem}
          onClose={() => { setConsumeModalOpen(false); setSelectedItem(null); }}
          onSuccess={() => { setConsumeModalOpen(false); fetchItems(); }}
        />
      )}

      {/* History Modal */}
      {historyModalOpen && selectedItem && (
        <HistoryModal 
          item={selectedItem}
          transactions={transactions}
          onClose={() => { setHistoryModalOpen(false); setSelectedItem(null); }}
        />
      )}
    </div>
  );
}

// -------------------------------------------------------------
// Sub-components for Modals
// -------------------------------------------------------------

function AddItemModal({ onClose, onSuccess }: { onClose: () => void, onSuccess: () => void }) {
  const [formData, setFormData] = useState<InventoryItemRequest>({
    name: '',
    category: '',
    unit: 'Piece',
    currentStock: 0,
    minimumStock: 0,
    costPerUnit: 0,
    sellingPricePerUnit: 0
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await inventoryApi.createItem(formData);
      if (res.success) onSuccess();
    } catch(err) {
      alert("Failed to create item.");
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
        <div className="p-4 border-b font-bold text-lg flex justify-between">
          <span>Add New Inventory Item</span>
          <button type="button" onClick={onClose}><X className="w-5 h-5 text-gray-500" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-4 flex flex-col gap-4">
          <input className="border p-2 rounded" placeholder="Name (e.g. 5W-30 Oil)" required onChange={(e) => setFormData({...formData, name: e.target.value})} />
          <input className="border p-2 rounded" placeholder="Category" required onChange={(e) => setFormData({...formData, category: e.target.value})} />
          <input className="border p-2 rounded" placeholder="Unit (Litre, Piece, etc)" required onChange={(e) => setFormData({...formData, unit: e.target.value})} />
          <div className="grid grid-cols-2 gap-2">
            <input type="number" className="border p-2 rounded" placeholder="Initial Stock" onChange={(e) => setFormData({...formData, currentStock: Number(e.target.value)})} />
            <input type="number" className="border p-2 rounded" placeholder="Min Alert Level" onChange={(e) => setFormData({...formData, minimumStock: Number(e.target.value)})} />
          </div>
          <div className="grid grid-cols-2 gap-2">
            <input type="number" className="border p-2 rounded" placeholder="Cost Price (Rs)" onChange={(e) => setFormData({...formData, costPerUnit: Number(e.target.value)})} />
            <input type="number" className="border p-2 rounded" placeholder="Selling Price (Rs)" onChange={(e) => setFormData({...formData, sellingPricePerUnit: Number(e.target.value)})} />
          </div>
          <div className="flex justify-end gap-2 mt-4">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded hover:bg-gray-50">Cancel</button>
            <button type="submit" className="px-4 py-2 bg-black text-white rounded hover:bg-gray-900">Save Item</button>
          </div>
        </form>
      </div>
    </div>
  )
}

function ReceiveStockModal({ item, onClose, onSuccess }: { item: InventoryItem, onClose: () => void, onSuccess: () => void }) {
  const [qty, setQty] = useState(0);
  const [notes, setNotes] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await inventoryApi.updateStock(item.id, {
        type: 'RECEIVE',
        quantity: qty,
        notes: notes
      });
      if (res.success) onSuccess();
    } catch(err) {
      alert("Failed to receive stock.");
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden">
        <div className="p-4 border-b font-bold text-lg flex justify-between">
          <span>Receive Stock</span>
          <button type="button" onClick={onClose}><X className="w-5 h-5 text-gray-500" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-4 flex flex-col gap-4">
          <p className="font-semibold">{item.name}</p>
          <p className="text-sm text-gray-500">Current Stock: <b>{item.currentStock} {item.unit}</b></p>
          <input type="number" step="0.01" className="border p-2 rounded" placeholder="Quantity to Add" required onChange={(e) => setQty(Number(e.target.value))} />
          <input className="border p-2 rounded" placeholder="Notes (Supplier, invoice #)" onChange={(e) => setNotes(e.target.value)} />
          <div className="flex justify-end gap-2 mt-4">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded hover:bg-gray-50">Cancel</button>
            <button type="submit" className="px-4 py-2 bg-[#ff5d2e] text-white rounded hover:bg-[#ff5d2e]/90">Receive</button>
          </div>
        </form>
      </div>
    </div>
  )
}

function ConsumeStockModal({ item, onClose, onSuccess }: { item: InventoryItem, onClose: () => void, onSuccess: () => void }) {
  const [qty, setQty] = useState(0);
  const [notes, setNotes] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (qty > item.currentStock) {
      alert("Cannot issue more than current stock!");
      return;
    }
    try {
      const res = await inventoryApi.updateStock(item.id, {
        type: 'CONSUME',
        quantity: qty,
        notes: notes
      });
      if (res.success) onSuccess();
    } catch(err) {
      alert("Failed to issue stock.");
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden">
        <div className="p-4 border-b font-bold text-lg flex justify-between text-black">
          <span>Issue to Mechanic / Service</span>
          <button type="button" onClick={onClose}><X className="w-5 h-5 text-gray-500" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-4 flex flex-col gap-4">
          <p className="font-semibold">{item.name}</p>
          <p className="text-sm text-gray-500">Available Stock: <b>{item.currentStock} {item.unit}</b></p>
          <input type="number" step="0.01" max={item.currentStock} className="border p-2 rounded" placeholder="Quantity to Issue" required onChange={(e) => setQty(Number(e.target.value))} />
          <input className="border p-2 rounded" placeholder="Note (Mechanic Name / Job #)" required onChange={(e) => setNotes(e.target.value)} />
          <div className="flex justify-end gap-2 mt-4">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded hover:bg-gray-50">Cancel</button>
            <button type="submit" className="px-4 py-2 bg-black text-white rounded hover:bg-gray-900">Issue Stock</button>
          </div>
        </form>
      </div>
    </div>
  )
}

function HistoryModal({ item, transactions, onClose }: { item: InventoryItem, transactions: StockTransaction[], onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[80vh]">
        <div className="p-4 border-b font-bold text-lg flex justify-between">
          <span>{item.name} - Stock History</span>
          <button onClick={onClose}><X className="w-5 h-5 text-gray-500 hover:text-black"/></button>
        </div>
        <div className="p-4 overflow-y-auto flex-1 flex flex-col gap-3">
          {transactions.length === 0 ? <p className="text-gray-500">No transactions recorded.</p> :
            transactions.map(tx => (
              <div key={tx.id} className="border p-3 rounded-lg flex justify-between items-center text-sm">
                <div>
                  <p className="font-semibold">{tx.type} <span className={tx.type === 'RECEIVE' ? 'text-green-600' : 'text-red-500'}>{tx.type === 'RECEIVE' ? '+' : '-'}{tx.quantity}</span></p>
                  <p className="text-gray-500 text-xs">{new Date(tx.createdAt).toLocaleString()} by {tx.performedBy}</p>
                </div>
                <div className="text-gray-500 italic max-w-[150px] truncate">{tx.notes}</div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}
