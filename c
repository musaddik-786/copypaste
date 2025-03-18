const handlePlacementClick = (placementName) => {
  setSelectedPlacement((prev) =>
    prev === placementName ? null : placementName
  );
  setSelectedProduct(null);
  setSelectedSubmission(null);
  setSelectedQuoteRequest(null);
};
