functional iteration
reverse: acc

	self cdr isCons ifFalse: [^ self error: 'Not a proper list'].
	^ self cdr reverse: (Cons car: self car cdr: acc)