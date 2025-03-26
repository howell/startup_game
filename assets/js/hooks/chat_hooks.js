// Chat related hooks for LiveView
const ChatHooks = {
  // Automatically scrolls to the bottom of a container when content changes
  ScrollToBottom: {
    mounted() {
      this.scrollToBottom();
      
      this.handleEvent("scroll-to-bottom", () => {
        this.scrollToBottom();
      });
    },
    
    updated() {
      this.scrollToBottom();
    },
    
    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight;
    }
  },
  
  // Automatically scrolls the window to the bottom when chat content changes
  WindowScrollToBottom: {
    mounted() {
      this.scrollToBottom();
      
      this.handleEvent("scroll-to-bottom", () => {
        this.scrollToBottom();
      });
    },
    
    updated() {
      this.scrollToBottom();
    },
    
    scrollToBottom() {
      // Use smooth scrolling for better UX
      window.scrollTo({
        top: document.body.scrollHeight,
        behavior: 'smooth'
      });
    }
  }
};

export default ChatHooks;
