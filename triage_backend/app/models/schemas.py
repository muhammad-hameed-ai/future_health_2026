from pydantic import BaseModel, Field, ConfigDict, model_validator
from typing import List, Optional

class EdgeRiskVector(BaseModel):
    """
    The lightweight probabilistic tensor sent from the on-device CNN.
    Contains no raw image data, ensuring zero-PII transmission.
    """
    model_config = ConfigDict(strict=True)

    class_probabilities: List[float] = Field(
        ..., 
        description="List of probabilities from the edge CNN",
        min_length=2
    )
    inference_latency_ms: float = Field(..., gt=0)
    domain_shift_detected: bool = Field(default=False)

    @model_validator(mode='after')
    def validate_probabilities(self) -> 'EdgeRiskVector':
        if not (0.99 <= sum(self.class_probabilities) <= 1.01):
            raise ValueError("Class probabilities must sum to 1.0")
        return self

class PatientContext(BaseModel):
    """
    Anonymized demographic and symptom data for RAG context.
    """
    age_bracket: str = Field(..., pattern=r"^(\d{2}-\d{2}|\d{2}\+)$")
    primary_symptom_duration_days: int = Field(..., ge=1)
    comorbidities: Optional[List[str]] = Field(default_factory=list)

class TriageRequest(BaseModel):
    """
    The combined payload received by the FastAPI endpoint.
    """
    risk_vector: EdgeRiskVector
    patient_context: PatientContext

class TriageResponse(BaseModel):
    """
    The structured clinical navigation returned to the user.
    """
    recommended_action: str = Field(..., description="e.g., 'Routine Screening', 'Urgent Dermatology Referral'")
    timeframe_days: int = Field(..., ge=0)
    clinical_rationale: str = Field(..., description="Grounded explanation from RAG pipeline")
    requires_human_verification: bool = Field(default=True)