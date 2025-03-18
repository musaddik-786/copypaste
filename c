return (
  <table className="placement-table">
    <thead>
      <tr>
        <th>Details</th>
        <th>Client</th>
        <th>Market</th>
        <th>Inception Date</th>
        <th>Expiration Date</th>
        <th>Status</th>
        <th>Lead Broker</th>
      </tr>
    </thead>
    <tbody>
      {placements.map((placement, index) => (
        <React.Fragment key={index}>
          <tr onClick={() => handlePlacementClick(placement.placementName)}>
            <td>
              {selectedPlacement === placement.placementName ? "-" : "+"}{" "}
              {placement.placementName}
            </td>
            <td>{placement.client}</td>
            <td>{placement.market}</td>
            <td>{placement.inceptionDate}</td>
            <td>{placement.expirationDate}</td>
            <td>{placement.status}</td>
            <td>{placement.leadBroker}</td>
          </tr>
          {/* Products ka rendering yahan aayega */}
        </React.Fragment>
      ))}
    </tbody>
  </table>
);
