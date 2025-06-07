Rails.application.config.dartsass.builds = {
  "."=> "."
}

Rails.application.config.dartsass.build_options \
<< "--load-path=node_modules/@uswds/uswds/packages" \
<< "--quiet-deps"
