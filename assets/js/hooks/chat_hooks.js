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
  }
};

export default ChatHooks;
