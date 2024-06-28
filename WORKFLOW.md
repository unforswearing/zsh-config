```
 ┌─────────────┐              ┌───────────────────────────────────────────────────────────────┐
 │    $HOME    │              │                       $HOME/zsh-config                        │
 └─────────────┘              └───────────────────────────────────────────────────────────────┘
                                                                                               
                                                                                               
  $HOME/.zshrc  ───Source──▶    $HOME/zsh-config/.zshrc                                        
                                                                                               
                                           │                                                   
                                           │                                                   
                                                                                               
                                         Source                                                
                                                                                               
                                           │                      ┌─▶ $HOME/zsh-config/req.zsh 
                                           ▼                      │                            
                                                                                               
                              $HOME/zsh-config/config.zsh  ──▶ Source                          
                                                                                               
                                           │                      │      exports               
                                                                  │      plugins               
                                          Exec                    └───▶  shell options         
                                                                         other settings        
                                           │                                                   
                                           ▼                                                   
                                                                                               
 $HOME/.zshenv  ◀─── Copy ──   $HOME/zsh-config/.zshenv                                        
                                                                                                                         
```