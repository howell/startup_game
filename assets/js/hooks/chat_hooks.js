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
  },
  
  // Handles Enter to submit, Shift+Enter for new line in textareas
  TextareaSubmit: {
    mounted() {
      this.el.addEventListener('keydown', (e) => {
        // If Enter is pressed without Shift
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault(); // Prevent default Enter behavior
          
          // Find the closest form and submit it
          const form = this.el.closest('form');
          if (form) {
            form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
          }
        }
        // If Shift+Enter, let the default behavior happen (new line)
      });
    }
  }
};

export default ChatHooks;
