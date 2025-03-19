const handleProductClick = (productName) => {
  setSelectedProduct((prev) => (prev === productName ? null : productName));
  setSelectedSubmission(null);
  setSelectedQuoteRequest(null);
};
