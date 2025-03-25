// ScrollDetection hook for handling navbar scrolling behavior
const ScrollDetection = {
  mounted() {
    const header = this.el;
    const menuOpenIcon = document.getElementById("menu-open-icon");
    const menuCloseIcon = document.getElementById("menu-close-icon");
    
    // Function to handle scroll event
    const handleScroll = () => {
      if (window.scrollY > 10) {
        header.classList.remove("py-5", "bg-transparent");
        header.classList.add("py-3", "bg-white/80", "backdrop-blur-md", "shadow-sm");
      } else {
        header.classList.add("py-5", "bg-transparent");
        header.classList.remove("py-3", "bg-white/80", "backdrop-blur-md", "shadow-sm");
      }
    };
    
    // Add scroll event listener
    window.addEventListener("scroll", handleScroll);
    
    // Initial check
    handleScroll();
    
    // Toggle menu icons when mobile menu is toggled
    this.handleEvent("js-exec:toggle", ({ to }) => {
      if (to === "#mobile-menu") {
        const isExpanded = header.getAttribute("aria-expanded") === "true";
        if (isExpanded) {
          menuOpenIcon.classList.remove("hidden");
          menuOpenIcon.classList.add("block");
          menuCloseIcon.classList.remove("block");
          menuCloseIcon.classList.add("hidden");
        } else {
          menuOpenIcon.classList.remove("block");
          menuOpenIcon.classList.add("hidden");
          menuCloseIcon.classList.remove("hidden");
          menuCloseIcon.classList.add("block");
        }
      }
    });
    
    // Handle toggle-aria-expanded event
    this.handleEvent("toggle-aria-expanded", ({ to }) => {
      const targetElement = document.querySelector(to);
      if (!targetElement) return;
      
      const isExpanded = targetElement.getAttribute("aria-expanded") === "true";
      targetElement.setAttribute("aria-expanded", !isExpanded);
      
      // Also toggle the menu icons when aria-expanded changes
      if (targetElement.id === header.id) {
        if (!isExpanded) {
          menuOpenIcon.classList.remove("block");
          menuOpenIcon.classList.add("hidden");
          menuCloseIcon.classList.remove("hidden");
          menuCloseIcon.classList.add("block");
        } else {
          menuOpenIcon.classList.remove("hidden");
          menuOpenIcon.classList.add("block");
          menuCloseIcon.classList.remove("block");
          menuCloseIcon.classList.add("hidden");
        }
      }
    });
    
    // Clean up event listener when component is removed
    this.destroy = () => {
      window.removeEventListener("scroll", handleScroll);
    };
  },
  destroyed() {
    if (this.destroy) this.destroy();
  }
};

// SmoothScroll hook for smooth scrolling when clicking navigation links
const SmoothScroll = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      e.preventDefault();
      
      const targetId = this.el.getAttribute("data-target");
      if (!targetId) return;
      
      const targetElement = document.querySelector(targetId);
      if (!targetElement) return;
      
      targetElement.scrollIntoView({
        behavior: "smooth"
      });
    });
  }
};

export default {
  ScrollDetection,
  SmoothScroll
};
