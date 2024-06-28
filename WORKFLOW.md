```
 ┌─────────────┐              ┌──────────────────────────────────────────────────┐ 
 │    $HOME    │              │                 $HOME/zsh-config                 │ 
 └─────────────┘              └──────────────────────────────────────────────────┘ 
                                                                                   
                                                                                   
  $HOME/.zshrc  ───Source──▶    $HOME/zsh-config/.zshrc                            
                                                                   aliases         
                                           │                       functions       
                                           │                       exports         
                                           ├──────▶ Source ─────▶  plugins         
                                           │                       shell options   
                                          Exec                     other settings  
                                           │                                       
                                           │                                       
                                           ▼                                       
                                                                                   
 $HOME/.zshenv  ◀─── Copy ──   $HOME/zsh-config/.zshenv                            
                                                                                                                                                                                  
```