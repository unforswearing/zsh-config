# Zsh Config

Somewhat complicated `zsh` configuration scripts. The overall size of the usable 
configuration in this repository is actively shrinking. See [Archive](/archive/)
for a full history of settings, scripts, and dsl experiments which ultimately 
went unused. 

See [LOG.md](/LOG.md) for "rationale".

```
┌───────────────────────┐              ┌──────────────────────────────────────────────────────────────────────────┐
│         $HOME         │              │                             $HOME/zsh-config                             │
└───────────────────────┘              └──────────────────────────────────────────────────────────────────────────┘
                                                                                                                   
                                                                                                                   
       $HOME/.zshrc  ─────Source─────▶    $HOME/zsh-config/.zshrc                                                  
                                                                                                                   
                                                     │                                                             
                                                     │                                                             
                                                                                                                   
                                                   Source                                                          
                                                                                                                   
                                                     │                          ┌───▶ $HOME/zsh-config/req.zsh     
                                                     ▼                          │                                  
                                                                                                                   
                                        $HOME/zsh-config/config.zsh  ──────▶ Source                                
                                                                                                                   
                                                     │                          │         exports                  
                                                                                │         plugins                  
                                                    Exec                        └──────▶  shell options            
                                                                                          other settings           
                                                     │                                                             
                                                     ▼                                                             
                                                                                                                   
      $HOME/.zshenv  ◀───── Copy ─────   $HOME/zsh-config/.zshenv                                                  
                                                                                                            
                                                                                                          
                                                                                                          
```