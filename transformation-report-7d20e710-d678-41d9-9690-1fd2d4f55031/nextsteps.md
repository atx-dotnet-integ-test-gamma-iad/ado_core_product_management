# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was previously reported:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a migration often point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Configuration`, `HttpContext`, threading, or serialization).

### 5. Review Removed or Replaced APIs
Check the code for any usage of APIs that were shimmed or replaced during transformation. Common areas to review include:

- `System.Web` references or any compatibility shims
- `BinaryFormatter` usage (removed in .NET 9, deprecated earlier)
- `AppDomain` usage
- `ConfigurationManager` — confirm the `Microsoft.Extensions.Configuration.ConfigurationManager` NuGet package is present if needed
- Windows-specific APIs if cross-platform support is a goal

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm runtime behavior matches expectations:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Review Output Artifacts
Confirm the compiled output is placed in the expected location and that all required assets (configuration files, static resources, etc.) are copied to the output directory. Check the `.csproj` for any missing `<Content>` or `<None>` items with `CopyToOutputDirectory` set appropriately.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment (no .NET runtime required on the target machine):

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify Published Output
Inspect the `./publish` directory to confirm all expected files are present, including configuration files and any native dependencies.

### 3. Smoke Test on Target Environment
Deploy the published output to the target environment and run a basic smoke test to confirm the application starts and core functionality operates correctly before wider release.