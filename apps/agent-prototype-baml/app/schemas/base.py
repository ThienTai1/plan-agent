from pydantic import BaseModel, ConfigDict

class BaseSchema(BaseModel):
    """
    Base schema with standard configuration for the project.
    In Pydantic v2, we use ConfigDict instead of a nested Config class.
    """
    model_config = ConfigDict(from_attributes=True)
