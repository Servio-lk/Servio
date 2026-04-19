import { useState, useEffect } from 'react';
import { 
  ReceiptText, 
  Search, 
  Plus, 
  Trash2, 
  User as UserIcon, 
  Calculator,
  Package,
  CheckCircle2,
  X
} from 'lucide-react';
import { billingApi } from '@/services/billingApi';
import type { BillRequest, BillItemRequest } from '@/services/billingApi';
import { inventoryApi } from '@/services/inventoryApi';
import type { InventoryItem } from '@/services/inventoryApi';
import { jsPDF } from "jspdf";
import autoTable from "jspdf-autotable";

export function AdminBilling() {
  const [billItems, setBillItems] = useState<BillItemRequest[]>([]);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [customerInfo, setCustomerInfo] = useState({
    name: '',
    address: '',
    phone: '',
    vehicleType: '',
    vehicleNo: '',
    paymentMode: 'CASH',
    meterReading: '',
    nextServiceDue: ''
  });

  const [searchQuery, setSearchQuery] = useState('');
  const [showItemSearch, setShowItemSearch] = useState(false);
  const [isFinalizing, setIsFinalizing] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    loadInventory();
  }, []);

  const loadInventory = async () => {
    try {
      const res = await inventoryApi.getAllItems();
      if (res.success) setInventory(res.data);
    } catch (err) {
      console.error('Failed to load inventory', err);
    }
  };

  const addItemToBill = (item: InventoryItem) => {
    const existing = billItems.find(i => i.inventoryItemId === item.id);
    if (existing) {
      setBillItems(billItems.map(i => 
        i.inventoryItemId === item.id 
          ? { ...i, quantity: i.quantity + 1, amount: (i.quantity + 1) * i.rate } 
          : i
      ));
    } else {
      setBillItems([...billItems, {
        inventoryItemId: item.id,
        description: item.name,
        quantity: 1,
        rate: item.sellingPricePerUnit,
        amount: item.sellingPricePerUnit
      }]);
    }
    setShowItemSearch(false);
  };

  const addManualItem = () => {
    setBillItems([...billItems, {
      description: 'Service Charge / Labor',
      quantity: 1,
      rate: 0,
      amount: 0
    }]);
  };

  const removeItem = (index: number) => {
    setBillItems(billItems.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, field: keyof BillItemRequest, value: any) => {
    const newItems = [...billItems];
    const item = { ...newItems[index], [field]: value };
    item.amount = item.quantity * item.rate;
    newItems[index] = item;
    setBillItems(newItems);
  };

  const subTotal = billItems.reduce((acc, curr) => acc + curr.amount, 0);
  const [discount, setDiscount] = useState(0);
  const netTotal = subTotal - discount;

  const handleFinalize = async () => {
    if (!customerInfo.name || !customerInfo.vehicleNo) {
      alert("Please enter Customer Name and Vehicle Number");
      return;
    }
    if (billItems.length === 0) {
      alert("Please add at least one item to the bill");
      return;
    }

    setIsFinalizing(true);
    try {
      const payload: BillRequest = {
        ...customerInfo,
        customerName: customerInfo.name,
        customerAddress: customerInfo.address,
        customerPhone: customerInfo.phone,
        currentMeterReading: customerInfo.meterReading,
        nextServiceDue: customerInfo.nextServiceDue,
        subTotal,
        discount,
        netTotal,
        items: billItems
      };

      const res = await billingApi.createBill(payload);
      if (res.success) {
        generatePDF(res.data);
        setSuccessMessage(`Invoice ${res.data.invoiceNo} created and stock updated!`);
        resetForm();
      }
    } catch (err: any) {
      console.error("Finalize error:", err);
      // Try to get specific error message if possible
      let msg = "Failed to finalize bill. Check stock availability.";
      if (err.message) msg = err.message;
      alert(msg);
    } finally {
      setIsFinalizing(false);
    }
  };

  const resetForm = () => {
    setBillItems([]);
    setCustomerInfo({
      name: '',
      address: '',
      phone: '',
      vehicleType: '',
      vehicleNo: '',
      paymentMode: 'CASH',
      meterReading: '',
      nextServiceDue: ''
    });
    setDiscount(0);
  };

  const generatePDF = (bill: any) => {
    const doc = new jsPDF();
    const brandColor: [number, number, number] = [255, 93, 46]; // #ff5d2e

    // Header
    doc.setFillColor(250, 250, 250);
    doc.rect(0, 0, 210, 40, 'F');
    
    // Logo / Brand
    const img = new Image();
    img.src = '/ServioLogo.png';
    doc.addImage(img, 'PNG', 15, 10, 30, 15);
    
    doc.setTextColor(100);
    doc.setFontSize(8);
    doc.setFont("helvetica", "normal");
    doc.text("Advanced Auto Care Specialist", 15, 32);

    // Invoice Info
    doc.setTextColor(0);
    doc.setFontSize(12);
    doc.text(`INVOICE: ${bill.invoiceNo}`, 140, 20);
    doc.setFontSize(10);
    doc.text(`Date: ${new Date(bill.date).toLocaleDateString()}`, 140, 27);
    doc.text(`Status: PAID`, 140, 34);

    // Customer & Vehicle Grid
    doc.setDrawColor(230);
    doc.line(15, 45, 195, 45);

    doc.setFontSize(10);
    doc.setTextColor(120);
    doc.text("CUSTOMER DETAILS", 15, 55);
    doc.text("VEHICLE DETAILS", 110, 55);

    doc.setTextColor(0);
    doc.setFont("helvetica", "bold");
    doc.text(bill.customerName.toUpperCase(), 15, 62);
    doc.text(bill.vehicleNo.toUpperCase(), 110, 62);

    doc.setFont("helvetica", "normal");
    doc.setTextColor(80);
    doc.text(bill.customerAddress || "N/A", 15, 68);
    doc.text(bill.customerPhone || "N/A", 15, 74);
    
    doc.text(`Type: ${bill.vehicleType || "Car"}`, 110, 68);
    doc.text(`Meter: ${bill.currentMeterReading || "N/A"}`, 110, 74);

    // Table
    const tableData = bill.items.map((item: any) => [
      item.description,
      parseFloat(item.quantity).toFixed(2),
      parseFloat(item.rate).toLocaleString('en-LK', { minimumFractionDigits: 2 }),
      parseFloat(item.amount).toLocaleString('en-LK', { minimumFractionDigits: 2 })
    ]);

    autoTable(doc, {
      startY: 85,
      head: [['Description', 'Qty', 'Rate (Rs.)', 'Amount (Rs.)']],
      body: tableData,
      theme: 'grid',
      headStyles: { fillColor: brandColor, textColor: 255 },
      styles: { fontSize: 9, cellPadding: 4 },
      columnStyles: {
        0: { cellWidth: 80 },
        1: { halign: 'center' },
        2: { halign: 'right' },
        3: { halign: 'right' }
      }
    });

    const finalY = (doc as any).lastAutoTable.finalY + 10;

    // Totals
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text("Sub Total:", 140, finalY);
    doc.text(subTotal.toLocaleString('en-LK', { minimumFractionDigits: 2 }), 195, finalY, { align: 'right' });

    doc.text("Discount:", 140, finalY + 7);
    doc.text(discount.toLocaleString('en-LK', { minimumFractionDigits: 2 }), 195, finalY + 7, { align: 'right' });

    doc.setFillColor(brandColor[0], brandColor[1], brandColor[2]);
    doc.rect(135, finalY + 12, 65, 12, 'F');
    doc.setTextColor(255);
    doc.setFont("helvetica", "bold");
    doc.text("NET TOTAL:", 140, finalY + 20);
    doc.text(`Rs. ${netTotal.toLocaleString('en-LK', { minimumFractionDigits: 2 })}`, 195, finalY + 20, { align: 'right' });

    // Footer
    doc.setTextColor(150);
    doc.setFontSize(8);
    doc.setFont("helvetica", "normal");
    doc.text("Thank you for choosing Servio for your vehicle needs.", 105, 280, { align: 'center' });
    doc.text("Computer generated invoice. No signature required.", 105, 285, { align: 'center' });

    doc.save(`Servio_Invoice_${bill.invoiceNo}.pdf`);
  };

  return (
    <div className="flex flex-col gap-6 max-w-[1200px] mx-auto w-full pb-10">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-black flex items-center gap-2">
            <Calculator className="w-7 h-7 text-[#ff5d2e]" />
            Billing Calculation
          </h1>
          <p className="text-sm text-black/60 mt-1">Generate professional invoices and manage checkout</p>
        </div>
        <div className="flex gap-2">
          <button 
            onClick={resetForm}
            className="px-4 py-2 text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Clear
          </button>
        </div>
      </div>

      {successMessage && (
        <div className="bg-green-50 border border-green-200 p-4 rounded-xl flex items-center justify-between text-green-700 animate-in fade-in slide-in-from-top-2">
          <div className="flex items-center gap-2 font-medium">
            <CheckCircle2 className="w-5 h-5" />
            {successMessage}
          </div>
          <button onClick={() => setSuccessMessage(null)} className="text-green-500 hover:text-green-700">
            <X className="w-5 h-5" />
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Customer & Vehicle */}
        <div className="lg:col-span-2 flex flex-col gap-6">
          <div className="bg-white p-6 rounded-2xl border border-black/5 shadow-sm space-y-6">
            <div className="flex items-center gap-2 border-b pb-4">
              <UserIcon className="w-5 h-5 text-[#ff5d2e]" />
              <h2 className="font-bold text-lg text-black">Customer & Vehicle Details</h2>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Customer Name</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.name}
                  onChange={e => setCustomerInfo({...customerInfo, name: e.target.value})}
                  placeholder="e.g. Kamal Perera"
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Vehicle Number</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.vehicleNo}
                  onChange={e => setCustomerInfo({...customerInfo, vehicleNo: e.target.value})}
                  placeholder="e.g. CAB-1234"
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Phone Number</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.phone}
                  onChange={e => setCustomerInfo({...customerInfo, phone: e.target.value})}
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Vehicle Type</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.vehicleType}
                  onChange={e => setCustomerInfo({...customerInfo, vehicleType: e.target.value})}
                  placeholder="e.g. SUV, Sedan"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t">
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Current Odometer</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.meterReading}
                  onChange={e => setCustomerInfo({...customerInfo, meterReading: e.target.value})}
                />
              </div>
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-500 uppercase">Next Service Due</label>
                <input 
                  type="text" 
                  className="w-full bg-gray-50 border-none rounded-xl p-3 focus:ring-2 focus:ring-[#ff5d2e] outline-none"
                  value={customerInfo.nextServiceDue}
                  onChange={e => setCustomerInfo({...customerInfo, nextServiceDue: e.target.value})}
                />
              </div>
            </div>
          </div>

          {/* Line Items Table */}
          <div className="bg-white rounded-2xl border border-black/5 shadow-sm overflow-hidden flex flex-col">
            <div className="p-6 border-b flex justify-between items-center bg-gray-50/50">
              <div className="flex items-center gap-2">
                <ReceiptText className="w-5 h-5 text-[#ff5d2e]" />
                <h2 className="font-bold text-lg text-black">Bill Items</h2>
              </div>
              <div className="flex gap-2">
                <button 
                  onClick={() => setShowItemSearch(true)}
                  className="bg-[#ff5d2e] text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-orange-600 transition-colors flex items-center gap-2"
                >
                  <Plus className="w-4 h-4" /> Add Part
                </button>
                <button 
                  onClick={addManualItem}
                  className="bg-black text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-gray-800 transition-colors flex items-center gap-2"
                >
                  <Plus className="w-4 h-4" /> Add Charge
                </button>
              </div>
            </div>

            <div className="overflow-x-auto min-h-[300px]">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b bg-gray-50/30">
                    <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider">Item / Description</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider text-center">Qty</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider text-right">Rate (Rs)</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-400 uppercase tracking-wider text-right">Amount</th>
                    <th className="px-6 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {billItems.map((item, index) => (
                    <tr key={index} className="hover:bg-gray-50/30 transition-colors">
                      <td className="px-6 py-4">
                        <input 
                          type="text"
                          className="w-full bg-transparent border-none p-0 focus:ring-0 text-black font-medium"
                          value={item.description}
                          onChange={(e) => updateItem(index, 'description', e.target.value)}
                        />
                        {item.inventoryItemId && (
                          <span className="text-[10px] bg-blue-50 text-blue-600 px-1.5 py-0.5 rounded font-bold uppercase mt-1 inline-block">Ref Inventory</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-center">
                        <input 
                          type="number"
                          className="w-16 bg-gray-100/50 border-none rounded p-1 text-center font-bold"
                          value={item.quantity}
                          min="0.01"
                          step="0.01"
                          onChange={(e) => updateItem(index, 'quantity', Number(e.target.value))}
                        />
                      </td>
                      <td className="px-6 py-4 text-right">
                        <input 
                          type="number"
                          className="w-24 bg-gray-100/50 border-none rounded p-1 text-right font-bold"
                          value={item.rate}
                          onChange={(e) => updateItem(index, 'rate', Number(e.target.value))}
                        />
                      </td>
                      <td className="px-6 py-4 text-right font-bold text-black">
                        {item.amount.toLocaleString()}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={() => removeItem(index)}
                          className="text-gray-300 hover:text-red-500 transition-colors p-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                  {billItems.length === 0 && (
                    <tr>
                      <td colSpan={5} className="px-6 py-20 text-center">
                        <div className="flex flex-col items-center gap-3 text-gray-400">
                          <ReceiptText className="w-12 h-12 opacity-20" />
                          <p>No items added. Start by adding a part or charge.</p>
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column: Checkout Summary */}
        <div className="flex flex-col gap-6">
          <div className="bg-white p-6 rounded-2xl border border-black/5 shadow-sm space-y-6 sticky top-[80px]">
            <div className="flex items-center gap-2 border-b pb-4">
              < Calculator className="w-5 h-5 text-[#ff5d2e]" />
              <h2 className="font-bold text-lg text-black">Bill Summary</h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center text-gray-600">
                <span>Sub-Total</span>
                <span className="font-bold">Rs. {subTotal.toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center text-gray-600">
                <span>Discount</span>
                <div className="flex items-center gap-2">
                  <span className="text-xs">Rs.</span>
                  <input 
                    type="number"
                    className="w-24 bg-gray-50 border-none rounded-lg p-2 text-right font-bold"
                    value={discount}
                    onChange={(e) => setDiscount(Number(e.target.value))}
                  />
                </div>
              </div>
              
              <div className="pt-4 border-t space-y-2">
                <div className="flex justify-between items-center text-black">
                  <span className="font-bold text-lg">Net Total</span>
                  <span className="font-black text-2xl text-[#ff5d2e]">Rs. {netTotal.toLocaleString()}</span>
                </div>
              </div>

              <div className="pt-4 space-y-3">
                <label className="text-xs font-bold text-gray-500 uppercase">Payment Mode</label>
                <div className="grid grid-cols-2 gap-2">
                  <button 
                    onClick={() => setCustomerInfo({...customerInfo, paymentMode: 'CASH'})}
                    className={`p-3 rounded-xl border text-sm font-bold transition-all ${
                      customerInfo.paymentMode === 'CASH' 
                      ? 'border-[#ff5d2e] bg-[#ffe7df] text-[#ff5d2e]' 
                      : 'border-gray-100 bg-gray-50 text-gray-500 hover:bg-gray-100'
                    }`}
                  >
                    CASH
                  </button>
                  <button 
                    onClick={() => setCustomerInfo({...customerInfo, paymentMode: 'CARD'})}
                    className={`p-3 rounded-xl border text-sm font-bold transition-all ${
                      customerInfo.paymentMode === 'CARD' 
                      ? 'border-[#ff5d2e] bg-[#ffe7df] text-[#ff5d2e]' 
                      : 'border-gray-100 bg-gray-50 text-gray-500 hover:bg-gray-100'
                    }`}
                  >
                    CARD
                  </button>
                </div>
              </div>
            </div>

            <button 
              onClick={handleFinalize}
              disabled={isFinalizing}
              className={`w-full py-4 rounded-xl flex items-center justify-center gap-3 font-bold text-white shadow-lg transition-all ${
                isFinalizing ? 'bg-gray-400' : 'bg-[#ff5d2e] hover:bg-orange-600 hover:shadow-orange-200'
              }`}
            >
              {isFinalizing ? (
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
              ) : (
                <>
                  <CheckCircle2 className="w-5 h-5" />
                  Finalize & Print PDF
                </>
              )}
            </button>
            <p className="text-[10px] text-center text-gray-400">
              * Finalizing will permanently decrease stock levels and log the transaction.
            </p>
          </div>
        </div>
      </div>

      {/* Item Search Overlay */}
      {showItemSearch && (
        <div className="fixed inset-0 z-[100] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-xl rounded-3xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-6 border-b flex justify-between items-center">
              <h3 className="font-bold text-xl flex items-center gap-2">
                <Package className="text-[#ff5d2e]" /> Search Inventory
              </h3>
              <button onClick={() => setShowItemSearch(false)} className="p-2 hover:bg-gray-100 rounded-full">
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>
            <div className="p-4">
              <div className="relative mb-4">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input 
                  type="text"
                  placeholder="Type part name (e.g. Filter)..."
                  autoFocus
                  className="w-full pl-12 pr-4 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#ff5d2e] outline-none text-lg"
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <div className="space-y-2 max-h-[400px] overflow-y-auto px-1 pb-4">
                {inventory.filter(i => i.name.toLowerCase().includes(searchQuery.toLowerCase())).map(item => (
                  <button 
                    key={item.id}
                    onClick={() => addItemToBill(item)}
                    disabled={item.currentStock <= 0}
                    className="w-full flex items-center justify-between p-4 rounded-2xl hover:bg-gray-50 transition-colors border border-transparent hover:border-black/5 text-left group"
                  >
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-gray-100 rounded-xl flex items-center justify-center text-gray-400 group-hover:bg-[#ffe7df] group-hover:text-[#ff5d2e] transition-colors">
                        <Package className="w-6 h-6" />
                      </div>
                      <div>
                        <p className="font-bold text-gray-900">{item.name}</p>
                        <p className="text-xs text-gray-500">{item.category} • {item.unit}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-black text-black">Rs. {item.sellingPricePerUnit.toLocaleString()}</p>
                      <p className={`text-[10px] font-bold ${item.currentStock > 0 ? 'text-green-500' : 'text-red-500'}`}>
                        {item.currentStock > 0 ? `IN STOCK: ${item.currentStock}` : 'OUT OF STOCK'}
                      </p>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
