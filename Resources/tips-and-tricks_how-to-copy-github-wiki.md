> author: Juwon1405

**How to import a github wiki**

Unfortunately, GitHub does not directly support the ability to fork a wiki page like you would a repository. However, you can clone the wiki as it is its own separate git repository.

Here's how you can do it:

1.  First, clone the original wiki repository you want to copy. For instance, if the repository is named `original_repo` and the user's name is `original_user`, you would do this:
    
    ```bash
    git clone https://github.com/original_user/original_repo.wiki.git
    ```
    
2.  Now create your own repository where you want to push the wiki. You can create a new repository on GitHub or use an existing one.
    
3.  Navigate to the cloned wiki directory and add a new remote for your repository. In this example, your username is `your_username` and your repository is `your_repo`:
    
    ```bash
    cd original_repo.wiki
    git remote add new_wiki https://github.com/your_username/your_repo.wiki.git
    ```
    
4.  Then push the cloned wiki content to your new wiki repository:
    
    ```perl
    git push -u new_wiki master
    ```
    

Now, the content of the original wiki has been copied to your new wiki repository. Note that while this method allows you to get the content of the original wiki, your new wiki won't automatically update if the original wiki gets updated. If you want to keep it up-to-date, you'll have to repeat this process.