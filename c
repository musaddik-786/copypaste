{selectedPlacement === placement.placementName &&
  placement.products.map((product, productIndex) => (
    <React.Fragment key={productIndex}>
      <tr
        className="product-row"
        onClick={() => handleProductClick(product.name)}
      >
        <td style={{ paddingLeft: "20px" }}>
          {selectedProduct === product.name ? "-" : "+"} {product.name}
        </td>
        <td>{placement.client}</td>
        <td></td>
        <td></td>
        <td></td>
        <td></td>
        <td>{placement.leadBroker}</td>
      </tr>
      {/* Submissions ka rendering yahan aayega */}
    </React.Fragment>
  ))
}
