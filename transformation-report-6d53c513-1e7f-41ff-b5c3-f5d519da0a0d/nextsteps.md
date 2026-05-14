# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency warnings, such as packages that target older frameworks or have been marked deprecated. Replace any such packages with their current equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only or otherwise platform-specific APIs. This can be done by adding the following property to the `.csproj` file temporarily:

```xml
<PlatformCompatibilityAnalyzer>true</PlatformCompatibilityAnalyzer>
```

Alternatively, review the build output for analyzer warnings prefixed with `CA1416`. Replace or conditionally guard any platform-specific calls that are not appropriate for cross-platform targets.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior is consistent. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Environment variable access
- Any reflection-based code that may behave differently under trimming or AOT scenarios

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your target environment:

**Framework-dependent:**
```bash
dotnet publish -c Release
```

**Self-contained for a specific platform:**
```bash
dotnet publish -c Release --runtime linux-x64 --self-contained true
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.