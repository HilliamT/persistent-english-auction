import heapq
import time

class PersistentEnglishAuction:
    def __init__(self, time_between_clearing, max_clears, auction_start_time = time.time()):
        
        # Configure the auction bids as a heap
        self.bids = []
        heapq.heapify(self.bids)
        
        # Set fields needed for auction
        self.winners = []
        self.time_between_clearings = time_between_clearing
        self.max_clearings = max_clears
        self.auction_start_time = auction_start_time
        self.active = time.time() > auction_start_time
        
    def add_bid(self, address, bid, bid_time = time.time()):
        
        while len(self.bids) > 0 and self.max_clearings > len(self.winners) and bid_time - len(self.winners) * self.time_between_clearings >= self.auction_start_time:
            self.winners.append(heapq.heappop(self.bids))
        
        # Add bid to the heap
        heapq.heappush(self.bids, (-bid, bid_time, address))
        
    def get_bidders(self):
        return self.bids
    
    def get_winners(self):
        return self.winners
    
    def close_auction(self):
        if not self.active:
            raise Exception("Auction is not active")
        
        self.active = False
        
        # pick winners until winners is full
        while len(self.bids) > 0 and len(self.winners) < self.max_clearings:
            self.winners.append(heapq.heappop(self.bids))