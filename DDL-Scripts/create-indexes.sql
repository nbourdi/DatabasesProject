-- INCOMPLETE


-- should speed up 3.7
CREATE INDEX idx_amount ON project (`amount`);
CREATE INDEX idx_type ON organization (`type`);
-- should speed up 3.3 & 3.6 and filters 
CREATE INDEX idx_end_date ON project (`end_date`);
CREATE INDEX idx_start_date ON project ('start_date');