const Tooltip = {
  mounted() {
    // Create tooltip element
    this.tooltipEl = document.createElement('div');
    this.tooltipEl.className = 'tooltip-content opacity-0 absolute z-50 px-2 py-1 bg-gray-800 text-white text-xs rounded pointer-events-none transition-opacity duration-200';
    this.tooltipEl.style.maxWidth = '250px';
    document.body.appendChild(this.tooltipEl);
    
    // Get text from data attribute
    this.text = this.el.dataset.tooltipText;
    this.position = this.el.dataset.tooltipPosition || 'top';
    
    // Setup event listeners
    this.el.addEventListener('mouseenter', this.showTooltip.bind(this));
    this.el.addEventListener('mouseleave', this.hideTooltip.bind(this));
    this.el.addEventListener('touchstart', this.onTouchStart.bind(this));
    document.addEventListener('touchend', this.onTouchEnd.bind(this));
    document.addEventListener('scroll', this.updatePosition.bind(this));
    window.addEventListener('resize', this.updatePosition.bind(this));

    // Track touch state
    this.isTouching = false;
  },
  
  showTooltip() {
    this.tooltipEl.textContent = this.text;
    this.tooltipEl.classList.remove('opacity-0');
    this.tooltipEl.classList.add('opacity-100');
    this.updatePosition();
  },
  
  hideTooltip() {
    if (!this.isTouching) {
      this.tooltipEl.classList.remove('opacity-100');
      this.tooltipEl.classList.add('opacity-0');
    }
  },
  
  onTouchStart(event) {
    event.preventDefault();
    this.isTouching = true;
    this.showTooltip();
  },

  onTouchEnd() {
    setTimeout(() => {
      this.isTouching = false;
      this.hideTooltip();
    }, 1500); // Auto-hide after 1.5 seconds on mobile
  },
  
  updatePosition() {
    const rect = this.el.getBoundingClientRect();
    const tooltipRect = this.tooltipEl.getBoundingClientRect();
    
    // Default offset from element
    const offset = 8;
    
    let top, left;
    
    switch(this.position) {
      case 'top':
        top = rect.top - tooltipRect.height - offset;
        left = rect.left + rect.width / 2 - tooltipRect.width / 2;
        break;
      case 'bottom':
        top = rect.bottom + offset;
        left = rect.left + rect.width / 2 - tooltipRect.width / 2;
        break;
      case 'left':
        top = rect.top + rect.height / 2 - tooltipRect.height / 2;
        left = rect.left - tooltipRect.width - offset;
        break;
      case 'right':
        top = rect.top + rect.height / 2 - tooltipRect.height / 2;
        left = rect.right + offset;
        break;
    }
    
    // Adjust position to keep tooltip in viewport
    if (left < 10) left = 10;
    if (left + tooltipRect.width > window.innerWidth - 10) {
      left = window.innerWidth - tooltipRect.width - 10;
    }
    if (top < 10) top = 10;
    if (top + tooltipRect.height > window.innerHeight - 10) {
      top = window.innerHeight - tooltipRect.height - 10;
    }
    
    this.tooltipEl.style.top = `${top}px`;
    this.tooltipEl.style.left = `${left}px`;
  },
  
  destroyed() {
    document.body.removeChild(this.tooltipEl);
    document.removeEventListener('touchend', this.onTouchEnd);
    document.removeEventListener('scroll', this.updatePosition);
    window.removeEventListener('resize', this.updatePosition);
  }
};

export default Tooltip; 