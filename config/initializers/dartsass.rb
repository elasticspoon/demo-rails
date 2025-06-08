Rails.application.config.dartsass.builds = {
  "application.scss" => "application.css"
}

Rails.application.config.dartsass.build_options \
<< "--load-path=node_modules/@uswds/uswds/packages" \
<< "--quiet-deps"
