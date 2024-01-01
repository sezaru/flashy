const hide = (liveSocket, element) => liveSocket.execJS(element, element.dataset.hide)

const updateProgress = (element, progress) => element.style.width = `${progress}%`

const FlashHook = {
    mounted() {
        this.isDismissible = this.el.dataset.dismissible === "true"

        if (!this.isDismissible) {
            return
        }

        this.progressElement = this.el.querySelector(`#${this.el.id}-progress`)

        const dismissTime = parseInt(this.el.dataset.dismissTime)

        const progressTimeout = dismissTime / 100

        this.counter = 0

        const updateCounter = () => {
            this.counter++

            updateProgress(this.progressElement, this.counter)

            if (this.counter == 100) {
                clearTimeout(this.timer)

                hide(this.liveSocket, this.el)
            } else {
                this.timer = setTimeout(updateCounter, progressTimeout)
            }
        }

        this.timer = setTimeout(updateCounter, progressTimeout)

        this.handleHideStart = () => {
            clearTimeout(this.timer)
        }

        this.handleMouseEnter = () => {
            clearTimeout(this.timer)

            this.counter = 0

            updateProgress(this.progressElement, this.counter)
        }

        this.handleMouseLeave = () => {
            this.timer = setTimeout(updateCounter, progressTimeout)
        }

        this.el.addEventListener("phx:hide-start", this.handleHideStart)
        this.el.addEventListener("mouseenter", this.handleMouseEnter)
        this.el.addEventListener("mouseleave", this.handleMouseLeave)
    },

    updated() {
        if (this.isDismissible) {
            updateProgress(this.progressElement, this.counter)
        }
    },

    destroyed() {
        this.el.removeEventListener("mouseleave", this.handleMouseLeave)
        this.el.removeEventListener("mouseenter", this.handleMouseEnter)
        this.el.removeEventListener("phx:hide-start", this.handleHideStart)

        if (!this.isDismissible) {
            return
        }

        clearTimeout(this.timer)
    }
}

export default FlashHook
