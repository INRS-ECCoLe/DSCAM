from bitarray import bitarray
from bitarray.util import ba2int

class binary_tree:
    def __init__(self, data):
        self.left = None
        self.right = None
        self.data = data
    # Insert Node
    def insert(self, data):
        if data < self.data:
            if self.left is None:
                self.left = binary_tree(data)
                return 1
            else:
                return(self.left.insert(data))
        elif data > self.data:
            if self.right is None:
                self.right = binary_tree(data)
                return 1
            else:
                return(self.right.insert(data))
        else:
            self.data = data
            return 0
    # Print the Tree
    def PrintTree(self):
        if self.left:
            self.left.PrintTree()
        print( self.data),
        if self.right:
            self.right.PrintTree()
    # Preorder traversal
    # Root -> Left ->Right
    def PreorderTraversal(self, root):
        res = []
        if root:
            res.append(root.data)
            res = res + self.PreorderTraversal(root.left)
            res = res + self.PreorderTraversal(root.right)
        return res

'''
root = binary_tree(27)
root.insert(14)
root.insert(35)
root.insert(10)
root.insert(19)

found = root.insert(30)
'''


