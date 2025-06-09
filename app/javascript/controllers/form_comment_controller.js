import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-comment"
export default class extends Controller {
  static targets = ["form", "button"]

  toggle() {
    this.formTarget.classList.toggle("display-none")
    this.buttonTarget.classList.toggle("display-none")
  }
}
