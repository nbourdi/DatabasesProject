-- 3.7
CREATE INDEX idx_amount ON project (`amount`);

-- 3.3 & 3.6 & 3.8 & filters 
CREATE INDEX idx_end_date ON project (`end_date`);

CREATE INDEX idx_start_date ON project ('start_date');

-- 3.6
CREATE INDEX idx_birth_date ON researcher ('birth_date');